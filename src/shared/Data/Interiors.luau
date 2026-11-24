--!strict
-- The insides of the town's buildings. The user: "could you detail each model much more, with
-- more attention to detail? for example, the interiors of buildings."
--
-- Every shop, tower, little house and public building on the map is a real room now: a shell
-- with a doorway you can walk through, a door that opens, a window you can see in at, and
-- furniture that suits what the place is (a bakery has loaves and a cake case, a library has
-- bookcases and reading tables, a cinema has rows of seats facing a screen).
--
--   Interiors.shell(r, spec)            the room: floor, walls, shop window, door. Returns its box.
--   Interiors.fill(r, kind, box)        the furniture for a kind of place
--
-- Everything is drawn in the building's own frame, front toward local -Z, like the rest of the
-- map's models. Pieces are a handful of parts each, so a furnished room costs 30 to 50.

local Recipe = require(script.Parent.Parent.Build.Recipe)

type R = Recipe.Recipe

local Interiors = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function shade(c: Color3, k: number): Color3
	return Color3.new(math.min(1, c.R * k), math.min(1, c.G * k), math.min(1, c.B * k))
end

local WHITE = rgb(250, 250, 248)
local CREAM = rgb(246, 236, 218)
local WOOD = rgb(196, 146, 96)
local WOOD_DARK = rgb(150, 104, 66)
local WOOD_PALE = rgb(226, 190, 140)
local METAL = rgb(186, 192, 202)
local DARK = rgb(64, 70, 86)
local GLASS = rgb(170, 216, 244)
local LEAF = rgb(84, 176, 74)
local POT = rgb(196, 120, 90)
local RED = rgb(236, 96, 90)
local BLUE = rgb(86, 150, 230)
local YELLOW = rgb(255, 208, 90)
local GREEN = rgb(110, 196, 110)
local PINK = rgb(255, 160, 184)
local PURPLE = rgb(170, 140, 230)
local TEAL = rgb(80, 190, 180)
local ORANGE = rgb(250, 150, 70)
local LAMPLIGHT = rgb(255, 236, 190)
local BRIGHTS = { RED, YELLOW, BLUE, GREEN, PINK, PURPLE, TEAL, ORANGE }

-- A room's inside: x1..x2 across, z1 (the front, where the door is) to z2 (the back), the floor's
-- top at y and the ceiling h above it.
export type Box = { x1: number, z1: number, x2: number, z2: number, y: number, h: number }

-- Small drawing helpers -------------------------------------------------------------------------------

-- A box between two corners, in the frame `f`.
local function slab(
	r: R,
	f: CFrame,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	mat: string?
): Recipe.Prim
	return r:boxAt(
		f * CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2),
		math.abs(x2 - x1),
		math.abs(y2 - y1),
		math.abs(z2 - z1),
		color,
		mat
	)
end

-- An upright cylinder standing on (x, y, z).
local function post(
	r: R,
	f: CFrame,
	x: number,
	y: number,
	z: number,
	height: number,
	d: number,
	color: Color3,
	mat: string?
)
	return r:add({
		shape = "Cylinder",
		cf = f * CFrame.new(x, y + height / 2, z) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(height, d, d),
		color = color,
		mat = mat or "SmoothPlastic",
	})
end

local function blob(r: R, f: CFrame, x: number, y: number, z: number, d: number, color: Color3, mat: string?)
	return r:lump(f * CFrame.new(x, y, z), d, d, d, color, mat)
end

-- A frame standing at (x, z) on the floor of a box, turned `yaw` degrees (0 faces the door).
local function at(box: Box, x: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, box.y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

-- Furniture: each is drawn round its own middle on the floor, its front toward -Z ----------------------

-- A shop counter with a till on it.
local function counter(r: R, f: CFrame, w: number, color: Color3)
	slab(r, f, -w / 2, 0, -1, w / 2, 3, 1, color, "Wood")
	slab(r, f, -w / 2 - 0.2, 3, -1.2, w / 2 + 0.2, 3.3, 1.2, WOOD_PALE, "Wood")
	slab(r, f, w / 2 - 2.2, 3.3, -0.6, w / 2 - 0.8, 4.1, 0.5, DARK, "Metal")
	slab(r, f, w / 2 - 2.1, 4.1, 0.1, w / 2 - 0.9, 4.9, 0.3, rgb(120, 200, 240), "Neon")
end

-- Shelves against a wall, `rows` high, with something on every shelf. `goods` says what:
-- "box", "ball", "book", "fold" (folded clothes), "pot" or "loaf".
local function shelves(r: R, f: CFrame, w: number, rows: number, goods: string, colors: { Color3 })
	local top = 1 + rows * 1.9
	slab(r, f, -w / 2, 0, 0.5, w / 2, top + 0.3, 0.8, WOOD_DARK, "Wood")
	for _, sx in { -1, 1 } do
		slab(r, f, sx * w / 2 - 0.15, 0, -0.9, sx * w / 2 + 0.15, top + 0.3, 0.5, WOOD_DARK, "Wood")
	end
	local n = 0
	for row = 0, rows - 1 do
		local y = 0.9 + row * 1.9
		slab(r, f, -w / 2, y, -0.9, w / 2, y + 0.2, 0.5, WOOD, "Wood")
		local count = math.max(2, math.floor(w / 2.4))
		for k = 1, count do
			n += 1
			local x = -w / 2 + (k - 0.5) * w / count
			local col = colors[(n - 1) % #colors + 1]
			if goods == "ball" then
				blob(r, f, x, y + 0.75, -0.2, 1.1, col)
			elseif goods == "book" then
				slab(r, f, x - 0.8, y + 0.2, -0.7, x + 0.8, y + 1.5, 0.3, col, "SmoothPlastic")
			elseif goods == "fold" then
				slab(r, f, x - 0.8, y + 0.2, -0.7, x + 0.8, y + 0.7, 0.3, col, "Fabric")
			elseif goods == "pot" then
				post(r, f, x, y + 0.2, -0.2, 0.6, 0.9, POT)
				blob(r, f, x, y + 1.15, -0.2, 0.9, col)
			elseif goods == "loaf" then
				r:lump(f * CFrame.new(x, y + 0.6, -0.2), 1.5, 0.8, 0.9, col)
			else
				slab(r, f, x - 0.5, y + 0.2, -0.6, x + 0.5, y + 1.2, 0.2, col, "SmoothPlastic")
			end
		end
	end
end

-- A round table with two stools.
local function tableSet(r: R, f: CFrame, top: Color3)
	post(r, f, 0, 0, 0, 2.4, 0.4, DARK, "Metal")
	post(r, f, 0, 2.4, 0, 0.3, 3.4, top, "Wood")
	for _, sx in { -1, 1 } do
		post(r, f, sx * 2.7, 0, 0, 1.7, 1.3, WOOD, "Wood")
	end
end

local function sofa(r: R, f: CFrame, w: number, color: Color3)
	slab(r, f, -w / 2, 0.4, -1.2, w / 2, 1.6, 1.2, color, "Fabric")
	slab(r, f, -w / 2, 1.6, 0.6, w / 2, 3.2, 1.4, shade(color, 0.92), "Fabric")
	for _, sx in { -1, 1 } do
		slab(r, f, sx * w / 2 - 0.4, 0.4, -1.2, sx * w / 2 + 0.4, 2.3, 1.4, shade(color, 0.86), "Fabric")
	end
end

-- A bed, its head toward +Z.
local function bed(r: R, f: CFrame, cover: Color3)
	slab(r, f, -2, 0, -3.4, 2, 1, 3.4, WOOD_DARK, "Wood")
	slab(r, f, -1.8, 1, -3.2, 1.8, 1.6, 3.2, WHITE, "Fabric")
	slab(r, f, -1.85, 1.6, -3.2, 1.85, 1.8, 1.2, cover, "Fabric")
	slab(r, f, -1.3, 1.6, 2, 1.3, 2.1, 3, WHITE, "Fabric")
	slab(r, f, -2, 0, 3.4, 2, 3, 3.7, WOOD_DARK, "Wood")
end

local function plant(r: R, f: CFrame)
	post(r, f, 0, 0, 0, 1.4, 1.6, POT)
	blob(r, f, 0, 2.4, 0, 2.4, LEAF)
	blob(r, f, 0.5, 3.4, -0.3, 1.5, shade(LEAF, 1.15))
end

-- A lamp hanging from the ceiling, lit after dark. `light` false keeps it from casting light
-- (a glow only), which is cheaper where there are many.
local function pendant(r: R, box: Box, x: number, z: number, light: boolean?)
	local top = box.y + box.h
	slab(r, CFrame.identity, x - 0.06, top - 1.6, z - 0.06, x + 0.06, top, z + 0.06, DARK, "Metal")
	local bulb = r:add({
		shape = "Cylinder",
		cf = CFrame.new(x, top - 2, z) * CFrame.Angles(0, 0, math.pi / 2),
		size = Vector3.new(0.8, 1.8, 1.8),
		color = LAMPLIGHT,
		mat = "SmoothPlastic",
	})
	if light == false then
		r:glow(bulb, 0)
	else
		r:glow(bulb, 22, 0.9)
	end
end

-- A picture on a wall: `f`'s -Z is the way it faces.
local function picture(r: R, f: CFrame, w: number, h: number, color: Color3)
	slab(r, f, -w / 2, 3.2, -0.15, w / 2, 3.2 + h, 0, WOOD_DARK, "Wood")
	slab(r, f, -w / 2 + 0.3, 3.5, -0.2, w / 2 - 0.3, 2.9 + h, -0.15, color, "SmoothPlastic")
end

-- A rail of clothes on hangers.
local function rack(r: R, f: CFrame, w: number)
	for _, sx in { -1, 1 } do
		post(r, f, sx * w / 2, 0, 0, 4.6, 0.3, METAL, "Metal")
	end
	slab(r, f, -w / 2, 4.4, -0.1, w / 2, 4.6, 0.1, METAL, "Metal")
	local count = math.max(3, math.floor(w / 1.3))
	for k = 1, count do
		local x = -w / 2 + (k - 0.5) * w / count
		slab(r, f, x - 0.45, 1.6, -0.7, x + 0.45, 4.3, 0.7, BRIGHTS[(k * 3) % #BRIGHTS + 1], "Fabric")
	end
end

-- A crate heaped with fruit or vegetables.
local function crate(r: R, f: CFrame, color: Color3)
	slab(r, f, -1.5, 0, -1.2, 1.5, 1.6, 1.2, WOOD, "WoodPlanks")
	for i, p in { { -0.7, -0.4 }, { 0.6, -0.3 }, { -0.1, 0.5 }, { 0.8, 0.6 } } do
		blob(r, f, p[1], 1.9 + (i % 2) * 0.2, p[2], 1.1, color)
	end
end

-- A glass display case with things in it.
local function case(r: R, f: CFrame, w: number, goods: { Color3 })
	slab(r, f, -w / 2, 0, -1, w / 2, 1.6, 1, WOOD_PALE, "Wood")
	local glass = slab(r, f, -w / 2, 1.6, -1, w / 2, 3.4, 1, GLASS, "Glass")
	glass.transp = 0.6
	local count = math.max(2, math.floor(w / 1.8))
	for k = 1, count do
		local x = -w / 2 + (k - 0.5) * w / count
		post(r, f, x, 1.6, 0, 0.7, 1.1, goods[(k - 1) % #goods + 1])
	end
end

local function desk(r: R, f: CFrame, w: number)
	slab(r, f, -w / 2, 2.4, -1.1, w / 2, 2.7, 1.1, WOOD, "Wood")
	for _, sx in { -1, 1 } do
		slab(r, f, sx * (w / 2 - 0.3) - 0.2, 0, -1, sx * (w / 2 - 0.3) + 0.2, 2.4, 1, WOOD_DARK, "Wood")
	end
end

local function chair(r: R, f: CFrame, color: Color3)
	slab(r, f, -0.8, 1.2, -0.8, 0.8, 1.5, 0.8, color, "SmoothPlastic")
	slab(r, f, -0.8, 1.5, 0.6, 0.8, 3.1, 0.8, color, "SmoothPlastic")
	slab(r, f, -0.7, 0, -0.7, 0.7, 1.2, 0.7, DARK, "Metal")
end

-- A waiting bench.
local function bench(r: R, f: CFrame, w: number)
	slab(r, f, -w / 2, 1.2, -0.7, w / 2, 1.5, 0.7, WOOD, "Wood")
	slab(r, f, -w / 2, 1.5, 0.5, w / 2, 2.9, 0.7, WOOD, "Wood")
	for _, sx in { -1, 1 } do
		slab(r, f, sx * (w / 2 - 0.4) - 0.15, 0, -0.6, sx * (w / 2 - 0.4) + 0.15, 1.2, 0.6, DARK, "Metal")
	end
end

-- Lift doors on a wall.
local function lift(r: R, f: CFrame)
	slab(r, f, -2.4, 0, -0.2, 2.4, 6.6, 0, shade(METAL, 0.8), "Metal")
	for _, sx in { -1, 1 } do
		slab(r, f, sx * 1.05 - 0.95, 0.1, -0.3, sx * 1.05 + 0.95, 6, -0.2, METAL, "Metal")
	end
	r:glow(slab(r, f, -0.5, 6.1, -0.3, 0.5, 6.5, -0.2, rgb(255, 180, 90), "SmoothPlastic"), 0)
end

-- A plinth with something worth looking at on it.
local function exhibit(r: R, f: CFrame, what: number)
	slab(r, f, -1.3, 0, -1.3, 1.3, 2.6, 1.3, WHITE, "Marble")
	if what % 3 == 0 then
		r:lump(f * CFrame.new(0, 3.6, 0) * CFrame.Angles(0.3, 0.6, 0.2), 2, 1.8, 1.6, rgb(150, 152, 170), "Slate")
	elseif what % 3 == 1 then
		post(r, f, 0, 2.6, 0, 1.6, 1.3, rgb(86, 150, 230))
		post(r, f, 0, 4.2, 0, 0.5, 0.7, rgb(86, 150, 230))
	else
		blob(r, f, 0, 3.5, 0, 1.6, rgb(240, 200, 90), "Metal")
		slab(r, f, -0.2, 2.6, -0.2, 0.2, 3, 0.2, DARK, "Metal")
	end
end

-- The room itself --------------------------------------------------------------------------------------

export type Shell = {
	w: number, -- outside width and depth; the front wall is at -d / 2
	d: number,
	h: number, -- the room's height, floor to ceiling
	wall: Color3,
	mat: string?,
	inside: Color3?, -- the inner walls' colour (plaster cream by default)
	floor: Color3?,
	floorMat: string?,
	trim: Color3?,
	doorX: number?, -- where along the front the door is (0, the middle, by default)
	doorW: number?,
	doorH: number?,
	door: Color3?,
	windows: boolean?, -- false for a front wall with only a door in it
	sill: number?, -- how high the shop window starts (1 by default)
}

-- Draws a room you can walk into: a floor, three walls, and a front with a shop window either
-- side of a door that opens. The caller puts the ceiling on (the storeys above, or a roof).
function Interiors.shell(r: R, s: Shell): Box
	local w, d, h = s.w, s.d, s.h
	local T = 0.8
	local mat = s.mat or "Plaster"
	local trim = s.trim or WHITE
	local doorX = s.doorX or 0
	local dw, dh = s.doorW or 4.2, math.min(s.doorH or 6.8, h - 0.8)
	local zf = -d / 2
	local f = CFrame.identity
	-- the floor, then the back and the sides
	slab(r, f, -w / 2, 0, zf, w / 2, 0.3, d / 2, s.floor or WOOD_PALE, s.floorMat or "WoodPlanks")
	slab(r, f, -w / 2, 0.3, d / 2 - T, w / 2, h, d / 2, s.wall, mat)
	for _, sx in { -1, 1 } do
		slab(r, f, sx * w / 2, 0.3, zf, sx * (w / 2 - T), h, d / 2 - T, s.wall, mat)
	end
	-- the front: a pier at each end, a lintel across the top, the door's posts, and either side
	-- of the door a low wall with a pane of glass over it
	local x1, x2 = doorX - dw / 2, doorX + dw / 2
	slab(r, f, -w / 2 + T, dh + 0.3, zf, w / 2 - T, h, zf + T, s.wall, mat)
	for _, e in { { -w / 2 + T, x1 }, { x2, w / 2 - T } } do
		local a, b = e[1], e[2]
		if b - a > 0.4 then
			if s.windows == false or b - a < 3 then
				slab(r, f, a, 0.3, zf, b, dh + 0.3, zf + T, s.wall, mat)
			else
				local sill = s.sill or 1
				slab(r, f, a, 0.3, zf, b, 0.3 + sill, zf + T, shade(s.wall, 0.86), mat)
				local pane = slab(r, f, a + 0.3, 0.3 + sill, zf + 0.3, b - 0.3, dh + 0.3, zf + 0.5, GLASS, "Glass")
				pane.transp = 0.55
				-- the window's frame: a sill, and a post at each end
				slab(r, f, a, 0.3 + sill, zf - 0.2, b, 0.6 + sill, zf + T, trim, "SmoothPlastic")
				slab(r, f, a, 0.6 + sill, zf, a + 0.3, dh + 0.3, zf + T, trim, "SmoothPlastic")
				slab(r, f, b - 0.3, 0.6 + sill, zf, b, dh + 0.3, zf + T, trim, "SmoothPlastic")
			end
		end
	end
	-- the door: its frame, a step, and a leaf that swings in (the World service opens it for a
	-- player's prompt and for any villager who walks up)
	slab(r, f, x1 - 0.3, 0.3, zf - 0.1, x1, dh + 0.3, zf + T, trim, "SmoothPlastic")
	slab(r, f, x2, 0.3, zf - 0.1, x2 + 0.3, dh + 0.3, zf + T, trim, "SmoothPlastic")
	slab(r, f, x1 - 0.3, dh + 0.3, zf - 0.1, x2 + 0.3, dh + 0.6, zf + T, trim, "SmoothPlastic")
	slab(r, f, x1 - 0.6, 0, zf - 1.4, x2 + 0.6, 0.3, zf, rgb(214, 214, 220), "Concrete")
	-- the doorway's own frame: X along the wall, Z into the room, so the leaf opens inward
	local doorway = CFrame.new(doorX, 0.3, zf + T / 2)
	local leaf = r:boxAt(doorway * CFrame.new(0, dh / 2, 0), dw, dh - 0.1, 0.3, s.door or rgb(92, 120, 160), "Wood")
	leaf.frame = doorway
	r:door(leaf, -dw / 2)
	local glassIn = r:boxAt(doorway * CFrame.new(0, dh * 0.62, 0), dw - 1.2, dh * 0.45, 0.36, GLASS, "Glass")
	glassIn.frame = doorway
	glassIn.transp = 0.5
	r:door(glassIn, -dw / 2)
	for _, sz in { -1, 1 } do
		local knob = r:lump(doorway * CFrame.new(dw / 2 - 0.5, dh * 0.42, sz * 0.3), 0.4, 0.4, 0.4, YELLOW, "Metal")
		knob.frame = doorway
		r:door(knob, -dw / 2)
	end
	return { x1 = -w / 2 + T, z1 = zf + T, x2 = w / 2 - T, z2 = d / 2 - T, y = 0.3, h = h - 0.3 }
end

-- Furnishing a room ---------------------------------------------------------------------------------

-- What the back shelves of each kind of shop hold: { goods, colours }.
local STOCK: { [string]: { any } } = {
	bakery = { "loaf", { rgb(226, 170, 100), rgb(240, 196, 120), rgb(200, 140, 84) } },
	grocer = { "box", { RED, GREEN, YELLOW, ORANGE } },
	books = { "book", BRIGHTS },
	clothes = { "fold", { BLUE, PINK, WHITE, TEAL, YELLOW } },
	cafe = { "box", { WHITE, CREAM, rgb(150, 104, 66) } },
	toys = { "ball", BRIGHTS },
	flowers = { "pot", { PINK, YELLOW, RED, PURPLE, WHITE } },
	post = { "box", { rgb(214, 172, 124), rgb(196, 150, 100), CREAM } },
	department = { "fold", BRIGHTS },
}

Interiors.ShopKinds = { "bakery", "grocer", "books", "clothes", "cafe", "toys", "flowers" }

-- A shop: shelves across the back, a counter with a till, something in the middle of the floor
-- that says what it sells, a rug inside the door, a plant, and lamps overhead.
local function shop(r: R, kind: string, b: Box)
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	local cx = (b.x1 + b.x2) / 2
	local stock = STOCK[kind] or STOCK.grocer
	-- shelves on the back wall (leaving the corner for the counter)
	local sw = math.min(w - 9, 16)
	shelves(r, at(b, b.x1 + 1 + sw / 2, b.z2 - 0.9), sw, 3, stock[1], stock[2])
	counter(r, at(b, b.x2 - 4.4, b.z2 - 5.2), 6.4, WOOD)
	slab(r, CFrame.identity, cx - 2.6, b.y, b.z1 + 0.4, cx + 2.6, b.y + 0.08, b.z1 + 4, rgb(214, 110, 100), "Fabric")
	plant(r, at(b, b.x2 - 1.6, b.z1 + 1.6))
	pendant(r, b, cx, (b.z1 + b.z2) / 2)
	local mx, mz = b.x1 + w * 0.34, b.z1 + d * 0.42
	if kind == "bakery" then
		case(r, at(b, mx, mz), 6, { PINK, WHITE, rgb(150, 104, 66), YELLOW })
		tableSet(r, at(b, b.x1 + 3.2, b.z1 + 3.4), WOOD_PALE)
	elseif kind == "grocer" then
		for i, col in { RED, GREEN, ORANGE } do
			crate(r, at(b, mx - 4 + i * 3.6, mz), col)
		end
		-- a fridge against the side wall
		slab(r, at(b, b.x1 + 1.2, b.z1 + d * 0.6), -1, 0, -2, 1, 6, 2, WHITE, "Metal")
		slab(r, at(b, b.x1 + 1.2, b.z1 + d * 0.6), 1, 1, -1.8, 1.1, 5.6, 1.8, GLASS, "Glass").transp = 0.5
	elseif kind == "books" then
		shelves(r, at(b, b.x1 + 0.9, b.z1 + d * 0.5, -90), math.min(d - 6, 10), 3, "book", BRIGHTS)
		sofa(r, at(b, mx + 1, mz, 200), 3, TEAL)
		slab(r, CFrame.identity, mx - 3, b.y, mz - 4, mx + 5, b.y + 0.08, mz + 2, PURPLE, "Fabric")
	elseif kind == "clothes" then
		rack(r, at(b, mx, mz, 20), 6)
		rack(r, at(b, b.x1 + 1.4, b.z1 + d * 0.55, 90), math.min(d - 7, 7))
		-- a mannequin
		local m = at(b, cx + 1, b.z1 + 2.6)
		post(r, m, 0, 0, 0, 0.3, 2, DARK, "Metal")
		post(r, m, 0, 0.3, 0, 2.6, 0.3, METAL, "Metal")
		slab(r, m, -0.9, 2.9, -0.5, 0.9, 5, 0.5, PINK, "Fabric")
		blob(r, m, 0, 5.6, 0, 1.1, CREAM)
	elseif kind == "cafe" then
		tableSet(r, at(b, mx - 1, mz - 1), WOOD_PALE)
		tableSet(r, at(b, mx + 5, mz + 2, 90), WOOD_PALE)
		sofa(r, at(b, b.x1 + 1.6, b.z1 + d * 0.6, -90), 5, ORANGE)
		-- the coffee machine on the counter
		slab(r, at(b, b.x2 - 6, b.z2 - 5.2), -0.9, 3.3, -0.6, 0.9, 5, 0.6, RED, "Metal")
	elseif kind == "toys" then
		-- a teddy, a ball and a tower of blocks
		local t = at(b, mx, mz)
		blob(r, t, 0, 1.3, 0, 2.6, rgb(196, 146, 96))
		blob(r, t, 0, 3.2, 0, 1.8, rgb(196, 146, 96))
		blob(r, t, -0.7, 4.1, 0, 0.7, rgb(170, 120, 76))
		blob(r, t, 0.7, 4.1, 0, 0.7, rgb(170, 120, 76))
		blob(r, t, 3.4, 1, 1, 2, RED)
		for i, col in { BLUE, YELLOW, GREEN } do
			slab(r, t, -4.4, (i - 1) * 1.3, -0.7, -3.1, i * 1.3, 0.6, col, "SmoothPlastic")
		end
	elseif kind == "flowers" then
		for i = 0, 4 do
			local bucket = at(b, mx - 4 + i * 2.4, mz + (i % 2) * 1.6)
			post(r, bucket, 0, 0, 0, 1.6, 1.5, METAL, "Metal")
			blob(r, bucket, -0.3, 2.3, 0, 1.2, BRIGHTS[i + 1])
			blob(r, bucket, 0.4, 2.6, 0.2, 1, BRIGHTS[(i + 3) % #BRIGHTS + 1])
			blob(r, bucket, 0, 2, 0.4, 1, LEAF)
		end
	elseif kind == "post" then
		-- parcels waiting, and scales on the counter
		local p = at(b, mx, mz)
		slab(r, p, -1.6, 0, -1.2, 1.6, 1.6, 1.2, rgb(214, 172, 124), "SmoothPlastic")
		slab(r, p, -1, 1.6, -0.9, 0.8, 2.6, 0.7, rgb(196, 150, 100), "SmoothPlastic")
		slab(r, p, 2, 0, -0.6, 3.6, 1.2, 1, CREAM, "SmoothPlastic")
		slab(r, at(b, b.x2 - 6, b.z2 - 5.2), -0.8, 3.3, -0.6, 0.8, 3.6, 0.6, METAL, "Metal")
		bench(r, at(b, b.x1 + 1.2, b.z1 + d * 0.5, -90), 5)
	end
end

-- A big shop floor: racks, cases and shelves in rows.
local function department(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local n = 0
	for x = b.x1 + 7, b.x2 - 7, 11 do
		n += 1
		local z = b.z1 + (b.z2 - b.z1) * 0.5
		if n % 3 == 1 then
			rack(r, at(b, x, z, 90), 7)
		elseif n % 3 == 2 then
			case(r, at(b, x, z), 5, BRIGHTS)
		else
			shelves(r, at(b, x, z, 90), 7, 2, "fold", BRIGHTS)
		end
		pendant(r, b, x, z - 5, n % 2 == 0)
	end
	shelves(r, at(b, cx, b.z2 - 0.9), math.min(b.x2 - b.x1 - 16, 40), 3, "box", BRIGHTS)
	counter(r, at(b, b.x2 - 5, b.z1 + 4, 180), 6.4, WOOD)
	counter(r, at(b, b.x1 + 5, b.z1 + 4, 180), 6.4, WOOD)
	slab(r, CFrame.identity, cx - 3, b.y, b.z1 + 0.4, cx + 3, b.y + 0.08, b.z1 + 5, RED, "Fabric")
end

-- A tower's lobby: a desk at the back, lifts behind it, sofas round a low table, plants.
local function lobby(r: R, b: Box, flats: boolean)
	local cx = (b.x1 + b.x2) / 2
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	slab(r, CFrame.identity, cx - 3, b.y, b.z1 + 0.4, cx + 3, b.y + 0.08, b.z2 - 6, rgb(196, 80, 84), "Fabric")
	lift(r, at(b, cx - 3.2, b.z2 - 0.05))
	lift(r, at(b, cx + 3.2, b.z2 - 0.05))
	if flats then
		-- letter boxes on the side wall and a bench under them
		local m = at(b, b.x1 + 0.1, b.z1 + d * 0.5, -90)
		for row = 0, 2 do
			for col = 0, 3 do
				slab(
					r,
					m,
					-3.4 + col * 1.7,
					2.6 + row * 1.2,
					-0.5,
					-1.9 + col * 1.7,
					3.6 + row * 1.2,
					0,
					METAL,
					"Metal"
				)
			end
		end
		bench(r, at(b, b.x2 - 1.2, b.z1 + d * 0.5, 90), 6)
	else
		counter(r, at(b, cx + w * 0.26, b.z1 + d * 0.5, 90), 7, rgb(120, 92, 70))
		sofa(r, at(b, b.x1 + 1.8, b.z1 + d * 0.38, -90), 6, BLUE)
		sofa(r, at(b, b.x1 + 6.4, b.z1 + d * 0.38 + 5, 180), 5, BLUE)
		slab(r, at(b, b.x1 + 6.4, b.z1 + d * 0.38), -1.4, 0, -1, 1.4, 1.3, 1, WOOD_PALE, "Wood")
	end
	plant(r, at(b, b.x1 + 1.6, b.z1 + 1.6))
	plant(r, at(b, b.x2 - 1.6, b.z1 + 1.6))
	picture(r, at(b, b.x2 - 0.05, b.z1 + d * 0.3, 90), 4, 2.6, TEAL)
	pendant(r, b, cx, b.z1 + d * 0.35)
	pendant(r, b, cx, b.z1 + d * 0.7, false)
end

-- A little house: a bed along the back wall, a table and a stool, a rug, a picture and a lamp.
local function home(r: R, b: Box, color: Color3)
	local cx, cz = (b.x1 + b.x2) / 2, (b.z1 + b.z2) / 2
	-- the bed lies along the back wall, its head to the right
	bed(r, at(b, b.x1 + 3.9, b.z2 - 2.3, 90), color)
	local t = at(b, b.x2 - 2.2, b.z1 + 2.6)
	post(r, t, 0, 0, 0, 2.2, 0.4, DARK, "Metal")
	post(r, t, 0, 2.2, 0, 0.3, 2.6, WOOD_PALE, "Wood")
	post(r, t, -2, 0, 0.4, 1.6, 1.2, WOOD, "Wood")
	blob(r, t, 0.3, 2.9, 0, 0.8, RED)
	slab(r, CFrame.identity, cx - 2.4, b.y, cz - 2, cx + 2, b.y + 0.08, cz + 1, shade(color, 1.1), "Fabric")
	picture(r, at(b, b.x2 - 0.05, cz + 1, 90), 2.4, 1.8, YELLOW)
	plant(r, at(b, b.x1 + 1.3, b.z1 + 1.3))
	pendant(r, b, cx, cz, false)
end

-- A beach hut: a bench along the back, a towel on a hook and a surfboard in the corner.
local function hut(r: R, b: Box, color: Color3)
	local cx = (b.x1 + b.x2) / 2
	bench(r, at(b, cx, b.z2 - 0.9), math.min(b.x2 - b.x1 - 1, 5))
	slab(r, CFrame.identity, b.x1 + 0.1, b.y + 2.6, b.z1 + 1.4, b.x1 + 0.4, b.y + 5.2, b.z1 + 2.8, color, "Fabric")
	r:boxAt(
		CFrame.new(b.x2 - 0.7, b.y + 3.1, b.z2 - 1.2) * CFrame.Angles(math.rad(8), 0, math.rad(6)),
		1.3,
		6,
		0.3,
		YELLOW,
		"SmoothPlastic"
	)
	blob(r, CFrame.identity, b.x1 + 1.2, b.y + 0.8, b.z1 + 1.2, 1.6, RED)
end

local function library(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local d = b.z2 - b.z1
	-- bookcases all along the back and down both sides
	for x = b.x1 + 5, b.x2 - 5, 9.4 do
		shelves(r, at(b, x, b.z2 - 0.9), 8.4, 4, "book", BRIGHTS)
	end
	for _, side in { -1, 1 } do
		local x = if side < 0 then b.x1 + 0.9 else b.x2 - 0.9
		shelves(r, at(b, x, b.z1 + d * 0.5, -90 * side), math.min(d - 8, 12), 4, "book", BRIGHTS)
	end
	-- reading tables with chairs, and the desk by the door
	for _, x in { cx - 13, cx + 13 } do
		local t = at(b, x, b.z1 + d * 0.45)
		desk(r, t, 8)
		for _, dx in { -2, 2 } do
			chair(r, t * CFrame.new(dx, 0, -2.2) * CFrame.Angles(0, math.pi, 0), TEAL)
			chair(r, t * CFrame.new(dx, 0, 2.2), TEAL)
		end
		pendant(r, b, x, b.z1 + d * 0.45)
	end
	counter(r, at(b, cx + 7, b.z1 + 3, 180), 6.4, WOOD_DARK)
	slab(r, CFrame.identity, cx - 3, b.y, b.z1 + 0.4, cx + 3, b.y + 0.08, b.z2 - 4, rgb(150, 60, 70), "Fabric")
	plant(r, at(b, b.x1 + 2, b.z1 + 2))
end

local function museum(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local d = b.z2 - b.z1
	local n = 0
	for x = b.x1 + 8, b.x2 - 8, 10 do
		n += 1
		exhibit(r, at(b, x, b.z1 + d * (if n % 2 == 0 then 0.35 else 0.62)), n)
	end
	-- paintings round the walls
	for i, x in { cx - 20, cx - 10, cx + 10, cx + 20 } do
		picture(r, at(b, x, b.z2 - 0.05, 0), 5, 3.4, BRIGHTS[i])
	end
	picture(r, at(b, b.x1 + 0.05, b.z1 + d * 0.5, -90), 6, 3.6, ORANGE)
	picture(r, at(b, b.x2 - 0.05, b.z1 + d * 0.5, 90), 6, 3.6, PURPLE)
	-- the big one in the middle: old bones on a long stand
	local m = at(b, cx, b.z1 + d * 0.5)
	slab(r, m, -6, 0, -2, 6, 0.8, 2, WHITE, "Marble")
	post(r, m, -3.4, 0.8, 0, 3.4, 0.4, CREAM)
	post(r, m, 3, 0.8, 0, 3.4, 0.4, CREAM)
	r:lump(m * CFrame.new(0, 4.6, 0), 9, 1.4, 1.6, CREAM)
	r:lump(m * CFrame.new(-5.6, 5.4, 0) * CFrame.Angles(0, 0, 0.5), 2.6, 1.6, 1.4, CREAM)
	bench(r, at(b, cx, b.z1 + 4, 180), 6)
	pendant(r, b, cx - 14, b.z1 + d * 0.5)
	pendant(r, b, cx + 14, b.z1 + d * 0.5)
	slab(r, CFrame.identity, cx - 3, b.y, b.z1 + 0.4, cx + 3, b.y + 0.08, b.z1 + 8, RED, "Fabric")
end

-- A cinema: the screen across the back, rows of seats stepping down toward it, popcorn by the door.
local function cinema(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local w, d = b.x2 - b.x1, b.z2 - b.z1
	r:glow(
		slab(
			r,
			CFrame.identity,
			cx - w * 0.36,
			b.y + 2.4,
			b.z2 - 0.5,
			cx + w * 0.36,
			b.y + b.h - 1,
			b.z2 - 0.3,
			WHITE,
			"SmoothPlastic"
		),
		30,
		0.7,
		rgb(200, 220, 255)
	)
	slab(
		r,
		CFrame.identity,
		cx - w * 0.38,
		b.y + 2,
		b.z2 - 0.55,
		cx + w * 0.38,
		b.y + 2.4,
		b.z2 - 0.2,
		DARK,
		"SmoothPlastic"
	)
	local rows = math.max(3, math.floor((d - 16) / 3.6))
	for row = 0, rows - 1 do
		local z = b.z1 + 9 + row * 3.6
		local seat = RED
		slab(r, CFrame.identity, cx - w * 0.36, b.y, z - 0.9, cx - 1.6, b.y + 1.3, z + 0.9, seat, "Fabric")
		slab(
			r,
			CFrame.identity,
			cx - w * 0.36,
			b.y + 1.3,
			z - 1.1,
			cx - 1.6,
			b.y + 3,
			z - 0.7,
			shade(seat, 0.88),
			"Fabric"
		)
		slab(r, CFrame.identity, cx + 1.6, b.y, z - 0.9, cx + w * 0.36, b.y + 1.3, z + 0.9, seat, "Fabric")
		slab(
			r,
			CFrame.identity,
			cx + 1.6,
			b.y + 1.3,
			z - 1.1,
			cx + w * 0.36,
			b.y + 3,
			z - 0.7,
			shade(seat, 0.88),
			"Fabric"
		)
	end
	-- the aisle's carpet, the popcorn counter and its machine
	slab(r, CFrame.identity, cx - 1.5, b.y, b.z1 + 0.4, cx + 1.5, b.y + 0.08, b.z2 - 4, rgb(120, 60, 130), "Fabric")
	counter(r, at(b, b.x1 + 6, b.z1 + 3.4, 180), 7, rgb(120, 92, 200))
	local pop = at(b, b.x1 + 4.4, b.z1 + 3.4)
	slab(r, pop, -0.9, 3.3, -0.7, 0.9, 5.4, 0.7, GLASS, "Glass").transp = 0.5
	blob(r, pop, 0, 4, 0, 1.2, YELLOW)
	slab(r, pop, -1, 5.4, -0.8, 1, 5.8, 0.8, RED, "SmoothPlastic")
	bench(r, at(b, b.x2 - 5, b.z1 + 1.4, 180), 6)
	picture(r, at(b, b.x2 - 0.05, b.z1 + 5, 90), 3, 4, YELLOW)
	pendant(r, b, cx, b.z1 + 4)
end

local function station(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local d = b.z2 - b.z1
	-- the ticket office: a counter behind glass, and the board of departures over it
	local t = at(b, cx - 22, b.z2 - 2.6)
	counter(r, t, 9, rgb(86, 110, 150))
	slab(r, t, -4.5, 3.3, -1.3, 4.5, 6, -1.1, GLASS, "Glass").transp = 0.55
	slab(r, CFrame.identity, cx - 8, b.y + 4.6, b.z2 - 0.4, cx + 8, b.y + 6.8, b.z2 - 0.2, DARK, "SmoothPlastic")
	for row = 0, 2 do
		r:glow(
			slab(
				r,
				CFrame.identity,
				cx - 7.4,
				b.y + 4.9 + row * 0.6,
				b.z2 - 0.5,
				cx + 3 - row * 2,
				b.y + 5.2 + row * 0.6,
				b.z2 - 0.4,
				rgb(255, 200, 90),
				"SmoothPlastic"
			),
			0
		)
	end
	for _, x in { cx - 6, cx + 8, cx + 22 } do
		bench(r, at(b, x, b.z1 + d * 0.5), 7)
		bench(r, at(b, x, b.z1 + d * 0.5 + 1.4, 180), 7)
	end
	-- a kiosk of papers and a luggage trolley
	shelves(r, at(b, b.x2 - 5, b.z2 - 0.9), 7, 2, "book", BRIGHTS)
	local l = at(b, cx + 30, b.z1 + 4)
	slab(r, l, -1.6, 0.4, -1, 1.6, 0.7, 1, METAL, "Metal")
	slab(r, l, -1.2, 0.7, -0.8, 0.2, 2.4, 0.8, rgb(150, 104, 66), "SmoothPlastic")
	slab(r, l, 0.3, 0.7, -0.6, 1.3, 1.8, 0.6, BLUE, "SmoothPlastic")
	plant(r, at(b, b.x1 + 2, b.z1 + 2))
	for _, x in { cx - 20, cx, cx + 20 } do
		pendant(r, b, x, b.z1 + d * 0.5, x ~= cx)
	end
end

-- A classroom: rows of desks facing the board, the teacher's desk and a globe.
local function school(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local d = b.z2 - b.z1
	for _, side in { -1, 1 } do
		local ox = cx + side * (b.x2 - b.x1) * 0.25
		slab(
			r,
			CFrame.identity,
			ox - 6,
			b.y + 2.6,
			b.z2 - 0.3,
			ox + 6,
			b.y + 6,
			b.z2 - 0.1,
			rgb(60, 110, 90),
			"SmoothPlastic"
		)
		slab(r, CFrame.identity, ox - 6.2, b.y + 2.3, b.z2 - 0.5, ox + 6.2, b.y + 2.6, b.z2 - 0.1, WOOD, "Wood")
		desk(r, at(b, ox + 4, b.z2 - 4), 5)
		for row = 0, 1 do
			for col = -1, 1 do
				local f = at(b, ox + col * 4.4, b.z1 + 5 + row * 4.2)
				desk(r, f, 3)
				chair(r, f * CFrame.new(0, 0, -1.8) * CFrame.Angles(0, math.pi, 0), if col == 0 then BLUE else YELLOW)
			end
		end
		pendant(r, b, ox, b.z1 + d * 0.5, side > 0)
	end
	-- a globe on a stand and coats on pegs by the door
	local g = at(b, cx + 3, b.z2 - 2)
	post(r, g, 0, 0, 0, 2.6, 0.3, WOOD_DARK, "Wood")
	blob(r, g, 0, 3.4, 0, 1.8, BLUE)
	for i = 0, 3 do
		slab(
			r,
			CFrame.identity,
			b.x1 + 0.1,
			b.y + 3,
			b.z1 + 2 + i * 1.6,
			b.x1 + 0.5,
			b.y + 5,
			b.z1 + 3 + i * 1.6,
			BRIGHTS[i + 1],
			"Fabric"
		)
	end
end

-- A clinic: reception, a row of chairs to wait on, and two beds behind curtains.
local function clinic(r: R, b: Box)
	local cx = (b.x1 + b.x2) / 2
	local d = b.z2 - b.z1
	counter(r, at(b, cx + 6, b.z1 + d * 0.45, 180), 7, WHITE)
	for i = 0, 3 do
		chair(r, at(b, b.x1 + 1.4, b.z1 + 3 + i * 2.2, -90), TEAL)
	end
	for i, x in { b.x2 - 4, b.x2 - 11 } do
		bed(r, at(b, x, b.z2 - 4), TEAL)
		slab(
			r,
			CFrame.identity,
			x - 3.2,
			b.y,
			b.z2 - 8.2,
			x - 3,
			b.y + 5.6,
			b.z2 - 1,
			if i == 1 then rgb(196, 232, 226) else WHITE,
			"Fabric"
		)
	end
	-- the cabinet of medicine and a set of scales
	shelves(r, at(b, b.x1 + 5, b.z2 - 0.9), 7, 3, "box", { WHITE, TEAL, RED })
	slab(r, CFrame.identity, cx - 1.2, b.y + 4, b.z2 - 0.3, cx + 1.2, b.y + 4.6, b.z2 - 0.1, RED, "SmoothPlastic")
	slab(r, CFrame.identity, cx - 0.3, b.y + 3.1, b.z2 - 0.3, cx + 0.3, b.y + 5.5, b.z2 - 0.1, RED, "SmoothPlastic")
	plant(r, at(b, b.x2 - 1.6, b.z1 + 1.6))
	pendant(r, b, cx, b.z1 + d * 0.5)
end

-- Furnishes a room for a kind of place. `tint` is a colour of the building's own to pick up.
function Interiors.fill(r: R, kind: string, b: Box, tint: Color3?)
	if kind == "lobby" then
		lobby(r, b, false)
	elseif kind == "flats" then
		lobby(r, b, true)
	elseif kind == "home" then
		home(r, b, tint or BLUE)
	elseif kind == "hut" then
		hut(r, b, tint or BLUE)
	elseif kind == "library" then
		library(r, b)
	elseif kind == "museum" then
		museum(r, b)
	elseif kind == "cinema" then
		cinema(r, b)
	elseif kind == "station" then
		station(r, b)
	elseif kind == "school" then
		school(r, b)
	elseif kind == "clinic" then
		clinic(r, b)
	elseif kind == "department" then
		department(r, b)
	else
		shop(r, kind, b)
	end
end

return Interiors
