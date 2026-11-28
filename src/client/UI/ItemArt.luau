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
