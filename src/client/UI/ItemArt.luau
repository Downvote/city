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

-- The apple: a round body dimpled at the top and bottom, its stalk, and one leaf standing off
-- its shoulder with clear space round it. The golden apple shares it.
local APPLE = "M12 7.25 C10.75 6.25 9.25 5.75 7.75 5.75 C4.5 5.75 2.5 8.5 2.5 12.25 C2.5 17.25 5.75 21.5 8.75 21.5 "
	.. "C10 21.5 10.75 20.75 12 20.75 C13.25 20.75 14 21.5 15.25 21.5 C18.25 21.5 21.5 17.25 21.5 12.25 "
	.. "C21.5 8.5 19.5 5.75 16.25 5.75 C14.75 5.75 13.25 6.25 12 7.25 Z"
local APPLE_LEAF = leaf(13.75, 6.5, 20.5, 3, 1.75)
local function apple(): Layers
	return {
		flat(APPLE),
		line("M12 7.75 C12 5.75 12.25 4.25 13.25 2.75", 2),
		clear(APPLE_LEAF, 1.5),
		flat(APPLE_LEAF),
	}
end

local Art: { [string]: Layers } = {}

Art.apple = apple()

-- The golden apple: the apple, and a sparkle off its shoulder.
local GLINT = sparkle(4.5, 4.25, 2.75)
Art.goldapple = apple()
table.insert(Art.goldapple, clear(GLINT, 1.5))
table.insert(Art.goldapple, flat(GLINT))

-- A bread roll: a domed loaf on a flat foot, two scores across its top.
Art.bread = {
	solid(
		"M2.5 17 C2.5 10.75 6.75 6.25 12 6.25 C17.25 6.25 21.5 10.75 21.5 17 C21.5 18.6 20.6 19.5 19 19.5 H5 C3.4 19.5 2.5 18.6 2.5 17 Z"
	),
	gap("M7.25 15 L10 10.25 M14 15 L16.75 10.25"),
}

-- A carrot pointing down to the left, and its leaves off the top with clear space round them.
local ROOT = "M2.75 21.25 C5 16 8.5 11.25 12.35 7.65 A3.5 3.5 0 0 1 17.35 12.65 C13.75 16.5 8 19 2.75 21.25 Z"
local GREENS = leaf(16.5, 7.5, 13.75, 2, 1.6) .. " " .. leaf(16.5, 7.5, 22, 5.5, 1.6)
Art.carrot = { flat(ROOT), clear(GREENS, 1.5), flat(GREENS) }

-- Cheese: a wedge, its top apart from its side, and two holes in the side.
Art.cheese = {
	solid("M2.5 11.5 L15.5 4.5 L21.5 7.75 V19.5 H2.5 Z"),
	gap("M1 12.25 L23 8.5"),
	hole(circle(8.25, 15.5, 2.25) .. " " .. circle(16, 14.25, 2.25)),
}

-- Soup: a bowl with its rim apart, and two wisps of steam over it.
Art.soup = {
	line("M8.75 9.5 C7 8 10.5 5.5 8.75 3", 2),
	line("M15.25 9.5 C13.5 8 17 5.5 15.25 3", 2),
	solid("M2.5 11.5 H21.5 C21.5 17 17.25 20.75 12 20.75 C6.75 20.75 2.5 17 2.5 11.5 Z"),
	gap("M1 14 H23"),
}

-- A grilled fish on a stick laid corner to corner, the stick out of its mouth: its body and
-- forked tail, its gills apart from its head, and an eye.
local FISH =
	"M3 12 C5 8 8.5 6.5 12 6.5 C14 6.5 15.5 7.25 16.5 8.75 L22 7.5 L20.25 12 L22 16.5 L16.5 15.25 C15.5 16.75 14 17.5 12 17.5 C8.5 17.5 5 16 3 12 Z"
Art.skewer = turned({
	line("M-1 12 L6 12", 2),
	flat(FISH),
	gap("M10 7.25 C11.25 9.25 11.25 14.75 10 16.75", 1.75),
	-- the eye, ahead of the gills (a circle can't be turned, so it is drawn as curves)
	hole(
		"M6.5 9.4 C7.27 9.4 7.9 10.03 7.9 10.8 C7.9 11.57 7.27 12.2 6.5 12.2 C5.73 12.2 5.1 11.57 5.1 10.8 C5.1 10.03 5.73 9.4 6.5 9.4 Z"
	),
}, -45, 12, 12)

-- A berry tart: three berries peeping over the rim of a shallow crust, apart from each other.
local CRUST = "M2 13.25 H22 L20.5 19 H3.5 Z"
Art.tart = {
	flat(circle(5, 10.25, 3.25) .. " " .. circle(12, 8.25, 3.5) .. " " .. circle(19, 10.25, 3.25)),
	clear(CRUST, 1.75),
	solid(CRUST),
}

-- Honey cake: a round cake, the honey on its top running down its side in two drips, and a
-- layer across it.
Art.honeycake = {
	solid(rect(2.5, 6.5, 19, 14, 2)),
	gap("M1 10.5 H6 C6 13.75 9.5 13.75 9.5 10.5 H14 C14 15 17.5 15 17.5 10.5 H23"),
	gap("M1 16.75 H23"),
}

-- A rice ball: rice pressed into a rounded triangle, a strip of seaweed round its foot.
Art.riceball = {
	solid(
		"M12 2.75 C13.5 2.75 14.5 3.75 15.5 5.5 L21 15.5 C22.4 18.25 21 21 18.25 21 H5.75 C3 21 1.6 18.25 3 15.5 L8.5 5.5 C9.5 3.75 10.5 2.75 12 2.75 Z"
	),
	gap("M7.75 22.5 V13.5 H16.25 V22.5"),
}

-- Pancakes: a stack of three, and a pat of butter on top.
Art.pancakes = {
	flat(rect(8.5, 2.5, 7, 3, 1)),
	flat(rect(3, 7.5, 18, 4, 2) .. " " .. rect(2, 12.5, 20, 4, 2) .. " " .. rect(3, 17.5, 18, 4, 2)),
	gap("M1 12 H23 M1 17 H23", 1.75),
}

-- Curry: a mound of rice on a plate, and a spoon resting beside it.
local BOWL =
	"M15.75 14.25 C14.9 13.4 15.15 11.9 16.25 10.75 C17.4 9.65 18.9 9.4 19.75 10.25 C20.6 11.1 20.35 12.6 19.25 13.75 C18.1 14.85 16.6 15.1 15.75 14.25 Z"
Art.curry = {
	flat("M2.5 14.75 C2.5 9.25 5.5 6 9.25 6 C13 6 16 9.25 16 14.75 Z"),
	clear(BOWL .. " M19 11 L21.5 3.5", 1.5),
	line("M19 11 L21 4", 1.75),
	flat(BOWL),
	solid("M2 16.5 H22 C21.5 19.25 17.5 21 12 21 C6.5 21 2.5 19.25 2 16.5 Z"),
}

-- A slice of pumpkin pie: its top, its side and the crust at its back.
Art.pie = {
	solid(
		"M2.5 16 L16.25 6.5 C18.5 5 21.5 6 21.5 9.25 V18.5 C21.5 19.6 20.6 20.5 19.5 20.5 H4.5 C3.4 20.5 2.5 19.6 2.5 18.5 Z"
	),
	gap("M1 16.25 H23 M15.25 6.25 C15.75 8.75 17.5 10.5 22.5 10.5"),
}

-- An ice cream: a scoop with a scalloped foot on a cone.
local SCOOP =
	"M4.75 10.25 A7.25 7.25 0 0 1 19.25 10.25 C19.25 12 18.25 13 17 13 C16 13 15.25 12.25 14.5 12.25 C13.5 12.25 13 13.25 12 13.25 C11 13.25 10.5 12.25 9.5 12.25 C8.75 12.25 8 13 7 13 C5.75 13 4.75 12 4.75 10.25 Z"
Art.icecream = {
	solid("M6.75 13 H17.25 L12.9 21.25 Q12 22.75 11.1 21.25 Z"),
	clear(SCOOP, 1.75),
	flat(SCOOP),
}

-- A salad: a bowl, and three leaves standing up out of it with clear space round each.
local LEAVES = leaf(9.5, 13.5, 4.5, 4.75, 2)
	.. " "
	.. leaf(12, 13.5, 12, 2.25, 2.25)
	.. " "
	.. leaf(14.5, 13.5, 19.5, 4.75, 2)
Art.salad = {
	flat(LEAVES),
	gap(leaf(12, 13.5, 12, 2.25, 2.25), 1.5),
	solid("M2.5 14.75 H21.5 C21.5 18.5 17.25 21 12 21 C6.75 21 2.5 18.5 2.5 14.75 Z"),
}

-- A bar of chocolate: six squares, two by three, and a bite out of its corner.
Art.chocolate = {
	solid(rect(4.5, 2, 15, 20, 1.5)),
	gap("M12 0.5 V23.5 M3 8.75 H21 M3 15.25 H21"),
	hole(circle(19.75, 2.25, 3.75)),
}

-- A caramel pudding on a plate: the custard wider at its foot, the caramel running over its top.
Art.pudding = {
	solid("M7.25 5 H16.75 L20 17.25 H4 Z"),
	gap("M2 9.25 H7 C7 12.25 10.25 12.25 10.25 9.25 H14.5 C14.5 11.25 17 11.25 17 9.25 H22"),
	flat(rect(2, 19, 20, 3, 1.5)),
}

-- Broccoli: a cloud of florets on a thick stalk, the stalk apart from the head.
local FLORETS =
	"M5.5 13 C3.25 13 2 11.25 2.25 9.25 C2.5 7.25 4.25 6 6.25 6.25 C6.75 3.75 9.25 2.25 12 2.5 C14.75 2.25 17.25 3.75 17.75 6.25 C19.75 6 21.5 7.25 21.75 9.25 C22 11.25 20.75 13 18.5 13 Z"
Art.broccoli = {
	solid("M8.5 12 H15.5 L14.5 21.5 H9.5 Z"),
	clear(FLORETS, 1.75),
	flat(FLORETS),
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
	flat(rect(6, 2, 12, 3.75, 1)),
	solid(rect(4, 7.5, 16, 14.5, 3.5)),
}
for _, layer in turned({ hole(gherkin(12, 14.75, 5, 10)) }, 30, 12, 14.75) do
	table.insert(Art.pickles, layer)
end

-- A hearty stew: a pot with two handles, food heaped over its rim.
local HEAP =
	"M5 10.75 C4.25 8.25 6 6.5 8.25 7 C9 4.75 11 3.75 13 4.25 C15.25 3.75 17.25 5.25 17.25 7.25 C19.25 7 20.5 8.75 19.5 10.75 Z"
Art.stew = {
	flat(HEAP),
	solid(
		"M2.5 12.5 H21.5 V14.5 H19.75 V16.75 C19.75 19.5 17.75 21.5 15 21.5 H9 C6.25 21.5 4.25 19.5 4.25 16.75 V14.5 H2.5 Z"
	),
	gap("M1 14.75 H23", 1.75),
}

-- A slice of star fruit: five fat points round a star cut out of its middle.
Art.starfruit = {
	solid(star(12, 12.75, 9.75, 4.9, 0.6), 1.5),
	hole(star(12, 12.75, 3.5, 1.6, 0.15)),
}

-- A fire chili: a fat pepper curling to a point, its cap apart from it, and its stalk.
local CHILI =
	"M13.5 8.5 C16.25 6.75 20.75 8 20.5 12.5 C20.25 17.25 13 21.25 2.75 21.5 C9 19.25 12 15.75 12.5 12 C12.75 10.25 12.75 9 13.5 8.5 Z"
Art.dragonchili = {
	flat(CHILI),
	gap("M12.5 11.75 Q16.5 9.75 21.25 11.25", 2),
	line("M17 8.5 C17 6 17.75 4.25 19.5 3.25", 2),
}

-- The other things a player carries (Data/Items: the bag and gifts), by the same rules. ------------

-- A strawberry: its body, a crown of leaves on top with clear space round it, and seeds.
local BERRY =
	"M12 21.5 C7 21.5 3 15 3 10.5 C3 7.75 5.25 6.5 8 6.5 H16 C18.75 6.5 21 7.75 21 10.5 C21 15 17 21.5 12 21.5 Z"
local CALYX = "M6 6.75 L8.75 2.75 L12 5 L15.25 2.75 L18 6.75 Q12 9.5 6 6.75 Z"
Art.strawberry = {
	flat(BERRY),
	clear(CALYX, 1.5),
	flat(CALYX),
	hole(circle(8.25, 11, 1.25) .. " " .. circle(15.75, 12.5, 1.25) .. " " .. circle(11, 16.75, 1.25)),
}

-- A bunch of herbs: three leaves on stalks tied with string.
Art.herbs = {
	flat(leaf(12, 13, 4.25, 4.5, 2.5)),
	flat(leaf(12, 13, 12, 2, 2.5)),
	flat(leaf(12, 13, 19.75, 4.5, 2.5)),
	solid(rect(9.5, 12, 5, 9.5, 1)),
	gap("M8 17.25 H16", 2),
}

-- Cookies: a round cookie with a bite out of it and three chips.
Art.cookie = {
	solid(circle(11.5, 12.5, 9.5)),
	hole(circle(20.5, 5, 4.25)),
	hole(circle(8, 10, 1.5) .. " " .. circle(14, 15.5, 1.5) .. " " .. circle(8.5, 16.5, 1.5)),
}

-- A jar of honey: its lid apart from the jar, and a label cut out of it.
Art.honey = {
	flat(rect(6, 2.5, 12, 4, 1)),
	solid(rect(4, 8.5, 16, 13, 3.5)),
	hole(rect(7.5, 12.25, 9, 5.5, 1)),
}

-- A cup of tea on its saucer: the cup, the tea's brim across its top, its handle, and steam.
Art.tea = {
	wisp(10.5, 6.75, 2.25),
	solid("M3.5 8.5 H17.5 V12.5 A7 7 0 0 1 10.5 19.5 A7 7 0 0 1 3.5 12.5 Z"),
	gap("M2 11 H19", 1.75),
	line("M17.5 10 H18.75 A2.75 2.75 0 0 1 18.75 15.5 H16.75", 2.25),
	flat(rect(2, 20, 20, 2.5, 1.25)),
}

-- A glass of orange juice: the glass with the juice's top cut across it, a straw, a slice on the rim.
local SLICE = circle(17.75, 6.25, 3.5)
Art.juice = {
	line("M9.5 9 L13 2.5", 2),
	solid("M5 6.5 H17 L15.5 21.5 H6.5 Z"),
	gap("M3 11 H19", 1.75),
	clear(SLICE, 1.5),
	flat(SLICE),
}

-- A storybook: its cover, the spine apart from it, and a star on the front.
Art.storybook = {
	solid(rect(4, 2.5, 16, 19, 1.5)),
	gap("M8 1 V23", 1.75),
	hole(star(14.25, 11.75, 4.5, 2.1, 0.35)),
}

-- A book of poems, open: two pages either side of the spine, lines of writing on each.
Art.poems = {
	flat("M11.25 6 C8.5 4.5 5.5 4.25 2.5 5 V19.5 C5.5 18.75 8.5 19 11.25 20.5 Z"),
	flat("M12.75 6 C15.5 4.5 18.5 4.25 21.5 5 V19.5 C18.5 18.75 15.5 19 12.75 20.5 Z"),
	gap("M4.75 9.5 H9.25 M4.75 13 H9.25", 1.5),
	gap("M14.75 9.5 H19.25 M14.75 13 H19.25", 1.5),
}

-- A tulip: its cup of petals split down the middle, the stalk and one leaf.
Art.tulip = {
	solid("M6.5 3.5 L9.25 6.75 L12 2.75 L14.75 6.75 L17.5 3.5 V9.75 A5.5 5.5 0 0 1 6.5 9.75 Z"),
	gap("M12 6.5 V15.5", 1.75),
	line("M12 15 V21.25", 2.25),
	flat(leaf(12, 21, 18.5, 13.5, 2)),
}

-- A daisy: a ring of round petals, the middle apart from them.
local PETALS = {}
for k = 0, 7 do
	local a = math.rad(k * 45)
	table.insert(PETALS, circle(12 + 6.5 * math.cos(a), 12 + 6.5 * math.sin(a), 3.1))
end
Art.daisy = {
	flat(table.concat(PETALS, " ")),
	flat(circle(12, 12, 5)),
	gap(circle(12, 12, 4), 1.75),
}

-- A sunflower: twelve pointed petals round a big middle, the middle apart from them, with seeds.
local function rays(cx: number, cy: number, R: number, r: number, count: number): string
	local out = {}
	for k = 0, count * 2 - 1 do
		local a = math.rad(-90 + k * 180 / count)
		local d = if k % 2 == 0 then R else r
		table.insert(out, (if k == 0 then "M" else "L") .. n(cx + d * math.cos(a)) .. " " .. n(cy + d * math.sin(a)))
	end
	table.insert(out, "Z")
	return table.concat(out, " ")
end
Art.sunflower = {
	solid(rays(12, 12, 10.25, 6.5, 12)),
	gap(circle(12, 12, 5.25), 1.75),
	hole(
		circle(10.5, 10.5, 1)
			.. " "
			.. circle(13.5, 10.5, 1)
			.. " "
			.. circle(10.5, 13.5, 1)
			.. " "
			.. circle(13.5, 13.5, 1)
	),
}

-- A bouquet: three flowers over a paper wrap, a ribbon round the wrap.
local HEADS = circle(7, 8, 3.75) .. " " .. circle(17, 8, 3.75)
Art.bouquet = {
	flat(circle(12, 5.75, 4)),
	clear(HEADS, 1.5),
	flat(HEADS),
	solid("M5 11.5 H19 L13.5 22 H10.5 Z"),
	gap("M3 15.75 H21", 1.75),
}

-- A drawing: a sheet with hills and a sun cut out of it.
Art.drawing = {
	solid(rect(2.5, 4, 19, 16, 1.5)),
	hole("M5 17.5 L9.5 10.5 L12.75 15 L15 12.5 L19 17.5 Z"),
	hole(circle(16.5, 8.25, 2)),
}

-- A toy boat: the hull, two sails apart over it, and a porthole.
Art.toyboat = {
	flat("M11 2.5 V12.5 H4 Z"),
	flat("M13 4.5 V12.5 H19.5 Z"),
	solid("M2.5 14 H21.5 L18.5 20.5 H5.5 Z"),
	hole(circle(12, 17, 1.75)),
}

-- A letter: an envelope with its flap cut across the front.
Art.letter = {
	solid(rect(2, 5, 20, 14.5, 1.5)),
	gap("M2.5 6.5 L12 13.5 L21.5 6.5", 1.75),
}

-- A seashell: a fan on its hinge, its ribs cut in.
Art.seashell = {
	solid("M12 19.5 L3 9.5 A9.25 9.25 0 0 1 21 9.5 Z"),
	gap("M12 17.5 L8.25 4.5 M12 17.5 L15.75 4.5", 1.5),
	flat(rect(8.75, 19.75, 6.5, 2.25, 1)),
}

-- A smooth pebble with a band round it.
Art.pebble = {
	solid(Vector.ellipse(12, 13, 10, 7.5)),
	gap("M2.5 14.25 Q12 8.5 21.5 11.75", 1.75),
}

-- An acorn: its cap, scored across, apart from the nut, and the stalk. The golden acorn shares it.
local function acorn(dx: number): Layers
	return {
		line(
			"M" .. n(12 + dx) .. " 5.5 C" .. n(12 + dx) .. " 4.5 " .. n(12.5 + dx) .. " 3.5 " .. n(13.75 + dx) .. " 3",
			2
		),
		solid(
			"M"
				.. n(4 + dx)
				.. " 10.25 A8 5.25 0 0 1 "
				.. n(20 + dx)
				.. " 10.25 Q"
				.. n(20 + dx)
				.. " 11.75 "
				.. n(18.5 + dx)
				.. " 11.75 H"
				.. n(5.5 + dx)
				.. " Q"
				.. n(4 + dx)
				.. " 11.75 "
				.. n(4 + dx)
				.. " 10.25 Z"
		),
		gap(
			"M"
				.. n(9.25 + dx)
				.. " 6 L"
				.. n(10.25 + dx)
				.. " 12 M"
				.. n(14.75 + dx)
				.. " 6 L"
				.. n(13.75 + dx)
				.. " 12",
			1.5
		),
		flat(
			"M"
				.. n(6 + dx)
				.. " 13.25 H"
				.. n(18 + dx)
				.. " V14.5 A6 7.25 0 0 1 "
				.. n(12 + dx)
				.. " 21.75 A6 7.25 0 0 1 "
				.. n(6 + dx)
				.. " 14.5 Z"
		),
	}
end
Art.acorn = acorn(0)

-- A golden acorn: the acorn moved over, and a sparkle off its shoulder.
local GLINT = sparkle(19.5, 4.75, 3)
Art.goldacorn = acorn(-1.5)
table.insert(Art.goldacorn, clear(GLINT, 1.5))
table.insert(Art.goldacorn, flat(GLINT))

-- A lucky coin: a rim apart from its face, and a star cut out of the face.
Art.luckycoin = {
	solid(circle(12, 12, 9.75)),
	gap(circle(12, 12, 7.75), 1.5),
	hole(star(12, 12.5, 5, 2.4, 0.3)),
}

-- A music box: its lid open over it, a note cut out of its front.
Art.musicbox = {
	flat("M3.5 9 L5.5 3 H20.5 L20 9 Z"),
	solid(rect(3, 10.5, 18, 11, 1.5)),
	hole(circle(10, 17.25, 2.25)),
	hole("M11.75 17 V12.75 H16 V14.5 H13.5 V17 Z"),
}

-- A snow globe: the glass ball with a fir cut out inside, apart from its base.
Art.snowglobe = {
	solid(circle(12, 9.75, 8)),
	hole("M12 4.25 L16 12.5 H13 V14.5 H11 V12.5 H8 Z"),
	flat(rect(4.5, 19, 15, 3.5, 1)),
}

return Art
