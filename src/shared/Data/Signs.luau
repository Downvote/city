--!strict
-- What the town's signs say. Every shop and public building has a name of its own, the billboards
-- and posters carry adverts for things you could find in a town like this one, the cinema has
-- films on, and the roads have names. All of it is made up for this game: no real brands, and
-- nothing from any other game.
--
-- Nothing here touches a Roblox service, so the specs can read it. The server's Signs service
-- draws the boards (Services/Signs); this file only says what goes on them and which one a board
-- at a given spot gets. A pick depends on the spot alone, so the town reads the same every time
-- it is built.
--
-- A design is a name, a short line under it, three colours and a layout:
--   bg      the board's own colour
--   fg      the lettering on it
--   accent  the leaning block, the stripes, the underline (words on the accent are drawn in bg)
--   style   which layout: see Signs.Styles
--   font    "round" (the game's display face), "tall" (condensed capitals) or "comic" (leaning capitals)
-- Shops carry a `short` word too, a few capitals that fit down a blade sign.

local Tuning = require(script.Parent.Parent.Config.Tuning)
local Town = require(script.Parent.Town)

local Signs = {}

export type Design = {
	name: string,
	line: string,
	short: string?,
	style: string,
	font: string,
	bg: Color3,
	fg: Color3,
	accent: Color3,
}

Signs.Styles = { "slab", "under", "split", "stripe", "frame", "bands", "tilt" }
Signs.Fonts = { "round", "tall", "comic" }
-- How a building's own board is laid out (the SignForm attribute): a fascia over a shopfront, a
-- board on the roof, a blade sticking out from the wall, a little hanging tile, a cinema marquee.
Signs.Forms = { "fascia", "roof", "blade", "tile", "marquee" }

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- The sign painter's tins. Strong flat colours that hold up next to each other.
local INK = rgb(28, 26, 34)
local WHITE = rgb(250, 248, 242)
local YELLOW = rgb(255, 208, 40)
local CORAL = rgb(240, 80, 70)
local TEAL = rgb(0, 150, 140)
local PINK = rgb(245, 50, 130)
local COBALT = rgb(38, 78, 222)
local VIOLET = rgb(112, 70, 220)
local GREEN = rgb(24, 140, 84)
local RED = rgb(214, 48, 48)
local NAVY = rgb(24, 40, 96)

Signs.Colors = {
	Ink = INK,
	White = WHITE,
	Yellow = YELLOW,
	Coral = CORAL,
	Teal = TEAL,
	Pink = PINK,
	Cobalt = COBALT,
	Violet = VIOLET,
	Green = GREEN,
	Red = RED,
	Navy = NAVY,
}

local TOWN = Tuning.Game.Name

local function design(
	name: string,
	short: string?,
	line: string,
	style: string,
	font: string,
	bg: Color3,
	fg: Color3,
	accent: Color3
): Design
	return { name = name, short = short, line = line, style = style, font = font, bg = bg, fg = fg, accent = accent }
end

-- Shops and public buildings ---------------------------------------------------------------------------

-- By kind (the SignKind attribute on a board; the shop kinds are Data/Interiors' own). A kind that
-- stands in more than one place has a few names, so two bakeries are not the same bakery.
Signs.Shops = {
	bakery = {
		design("Harlow's Bakery", "BREAD", "Warm loaves from six", "slab", "round", INK, YELLOW, CORAL),
		design("Second Rise", "BUNS", "Buns and pies all day", "under", "round", CORAL, WHITE, INK),
		design("Oven Door Bakery", "BAKERY", "Still warm at eight", "stripe", "tall", YELLOW, INK, COBALT),
	},
	grocer = {
		design("Pell Street Grocer", "FRESH", "Fruit and veg, picked this week", "split", "round", TEAL, WHITE, INK),
		design("Corner Basket", "FOOD", "Open till late", "frame", "tall", WHITE, INK, CORAL),
		design("Tam's Greengrocer", "FRUIT", "Ask about the plums", "bands", "round", YELLOW, INK, GREEN),
	},
	books = {
		design("Wren & Aldous Books", "BOOKS", "New books and old ones", "under", "round", COBALT, WHITE, YELLOW),
		design("Margin Notes", "READ", "Second hand, first rate", "slab", "tall", WHITE, INK, PINK),
		design("Chapter Nine", "BOOKS", "Ask us what to read next", "frame", "round", INK, WHITE, TEAL),
	},
	clothes = {
		design("Thimble & Thread", "WEAR", "Hems taken up same day", "split", "round", PINK, WHITE, INK),
		design("Loom Street", "STYLE", "New coats are in", "bands", "tall", INK, WHITE, PINK),
		design("Button Box", "COATS", "Fits you or we fix it", "stripe", "comic", WHITE, COBALT, CORAL),
	},
	cafe = {
		design("Kettle Corner", "COFFEE", "Hot drinks, cold cake", "under", "round", INK, WHITE, CORAL),
		design("The Slow Pour", "CAFE", "Open from seven", "slab", "tall", YELLOW, INK, COBALT),
		design("Plum Street Cafe", "TEA", "Scones till they run out", "frame", "round", VIOLET, WHITE, YELLOW),
	},
	toys = {
		design("Jumping Jack Toys", "TOYS", "Kites and marbles are in", "stripe", "comic", COBALT, YELLOW, WHITE),
		design("The Toy Cupboard", "PLAY", "Try it before you buy it", "bands", "round", YELLOW, INK, PINK),
		design("Wind Up Toys", "TOYS", "No batteries needed", "slab", "round", CORAL, WHITE, INK),
	},
	flowers = {
		design("Petal & Stem", "BLOOM", "Cut this morning", "under", "round", PINK, WHITE, INK),
		design("Marigold's", "FLORA", "Bunches from 4 coins", "split", "round", YELLOW, INK, PINK),
		design("The Potting Shed", "PLANTS", "Seeds and bulbs in season", "frame", "tall", TEAL, WHITE, INK),
		design("Fennel & Rose", "ROSES", "Flowers for any doorstep", "stripe", "round", WHITE, INK, PINK),
	},
	post = {
		design(TOWN .. " Post", "POST", "Stamps and parcels", "bands", "tall", RED, WHITE, YELLOW),
	},
	department = {
		design("Doyle & Finch", "STORE", "Three floors. Lifts at the back.", "split", "tall", INK, WHITE, YELLOW),
	},
	cinema = {
		design("The Starling", "CINEMA", "Now showing", "slab", "comic", INK, YELLOW, PINK),
	},
	station = {
		design(TOWN .. " Station", "TRAINS", "Platforms 1 and 2", "under", "tall", NAVY, WHITE, YELLOW),
	},
	library = {
		design(TOWN .. " Library", "BOOKS", "Open late on Thursdays", "frame", "tall", INK, WHITE, TEAL),
	},
	museum = {
		design(TOWN .. " Museum", "MUSEUM", "Old bones in the new wing", "bands", "tall", WHITE, INK, CORAL),
	},
	school = {
		design(TOWN .. " School", "SCHOOL", "Bell at half past eight", "under", "round", COBALT, WHITE, YELLOW),
	},
	clinic = {
		design("Harbour Clinic", "CLINIC", "Walk in, no need to book", "split", "round", WHITE, TEAL, CORAL),
	},
	fire = {
		design("Fire Station No. 1", "FIRE", "Keep the doors clear", "bands", "tall", RED, WHITE, YELLOW),
	},
	hotel = {
		design("The Lamplight Hotel", "HOTEL", "Rooms with a sea view", "frame", "round", INK, YELLOW, WHITE),
	},
	tower = {
		design("Beacon Tower", "TOWER", "Viewing deck on 26", "slab", "tall", COBALT, WHITE, YELLOW),
	},
	-- the office blocks downtown
	office = {
		design("Harbour House", "OFFICE", "Reception on the ground floor", "under", "tall", NAVY, WHITE, YELLOW),
		design("Quay Point", "OFFICE", "Offices to let on 6", "split", "tall", WHITE, INK, COBALT),
		design("Northlight House", "OFFICE", "Visitors please sign in", "frame", "round", INK, WHITE, TEAL),
		design("The Tern Building", "OFFICE", "Deliveries round the back", "bands", "tall", TEAL, WHITE, INK),
		design("Linden Chambers", "OFFICE", "Ferrier & Co on 3", "slab", "round", WHITE, INK, CORAL),
		design("Cobalt Court", "OFFICE", "Lift out of order again", "stripe", "tall", COBALT, WHITE, YELLOW),
		design("Signal Works", "OFFICE", "Studios and desks to rent", "under", "comic", YELLOW, INK, COBALT),
		design("Ferrier House", "OFFICE", "Ring for the porter", "frame", "tall", INK, YELLOW, CORAL),
	},
	-- the blocks of flats
	flats = {
		design("Orchard Court", "FLATS", "Flats 1 to 36", "frame", "round", WHITE, INK, CORAL),
		design("Sandpiper House", "FLATS", "Ring twice for the caretaker", "under", "round", TEAL, WHITE, YELLOW),
		design("Dovecote Flats", "FLATS", "No ball games on the stairs", "bands", "tall", INK, WHITE, PINK),
		design("Larkspur House", "FLATS", "Bins go out on Monday", "split", "round", VIOLET, WHITE, YELLOW),
		design("Chimney Row", "FLATS", "Post for 12 is next door", "stripe", "tall", CORAL, WHITE, INK),
		design("Gable House", "FLATS", "Flats 1 to 24", "slab", "round", YELLOW, INK, COBALT),
		design("Bluebell Court", "FLATS", "Mind the step", "under", "round", COBALT, WHITE, YELLOW),
		design("Kite Hill Flats", "FLATS", "Wipe your feet", "frame", "tall", WHITE, COBALT, CORAL),
		design("Sparrow House", "FLATS", "Flats 1 to 40", "bands", "round", PINK, WHITE, INK),
		design("Wicker Lane Flats", "FLATS", "Parcels go to number 2", "slab", "tall", INK, YELLOW, TEAL),
	},
} :: { [string]: { Design } }

-- Adverts ----------------------------------------------------------------------------------------------

-- What the billboards and posters sell (every part named Ad gets one).
Signs.Adverts = {
	design("Bramble Pop", nil, "Blackberry fizz in a can", "slab", "comic", VIOLET, WHITE, YELLOW),
	design("Hilltop Dairy", nil, "Milk from up the road", "bands", "round", WHITE, COBALT, CORAL),
	design("Lighthouse Radio", nil, "Songs you half remember", "tilt", "tall", INK, YELLOW, PINK),
	design("Pier Fair", nil, "Open till the last ferry", "stripe", "comic", PINK, WHITE, YELLOW),
	design("Long Spoon Noodles", nil, "Hot broth till midnight", "split", "round", RED, WHITE, INK),
	design("Island Bus Pass", nil, "Ride all week for 20 coins", "under", "tall", COBALT, WHITE, YELLOW),
	design("Two Left Feet", nil, "Shoes mended while you wait", "frame", "round", YELLOW, INK, COBALT),
	design("Harbour Catch", nil, "Landed this morning", "slab", "tall", TEAL, WHITE, INK),
	design("Wobble Cycles", nil, "Bikes by the hour", "tilt", "comic", WHITE, INK, TEAL),
	design("Tumble Laundry", nil, "Washed and folded by five", "bands", "round", COBALT, WHITE, WHITE),
	design("Drizzle & Co", nil, "Umbrellas that open first time", "under", "round", INK, WHITE, TEAL),
	design("Night Market", nil, "Fridays on Harbour Road", "stripe", "comic", INK, YELLOW, CORAL),
	design("B Side Records", nil, "Old songs in new sleeves", "split", "tall", PINK, WHITE, INK),
	design("The " .. TOWN .. " Gazette", nil, "Out every morning. Mostly true.", "frame", "tall", WHITE, INK, CORAL),
	design("Two Scoops", nil, "Sixteen flavours, one queue", "tilt", "round", PINK, WHITE, YELLOW),
	design("Fern & Trowel", nil, "Garden plants that forgive you", "slab", "round", GREEN, WHITE, YELLOW),
	design("Orchard Press", nil, "Apple juice with nothing added", "bands", "round", YELLOW, INK, GREEN),
	design("Islet Ferries", nil, "Boats leave on the hour", "under", "tall", WHITE, COBALT, CORAL),
	design("Plum Street Tea", nil, "A pot for two, 5 coins", "frame", "round", VIOLET, WHITE, YELLOW),
	design("The Starling", nil, "Double bill every Friday", "slab", "comic", INK, YELLOW, PINK),
	design("Pike's Hardware", nil, "Nails by the handful", "stripe", "tall", YELLOW, INK, COBALT),
	design("Gull Taxi", nil, "We know the short way", "split", "comic", YELLOW, INK, INK),
	design("Sock Drawer", nil, "Three pairs for 6 coins", "tilt", "comic", TEAL, WHITE, YELLOW),
	design("Top Floor Gym", nil, "No lift. That's the warm up.", "bands", "tall", INK, WHITE, CORAL),
} :: { Design }

-- What's on at the cinema (a part named Ad with AdKind "film" gets one of these).
Signs.Films = {
	design("The Quiet Lighthouse", nil, "Now showing", "bands", "tall", NAVY, WHITE, YELLOW),
	design("Rain on Tuesday", nil, "Held over a third week", "under", "round", COBALT, WHITE, YELLOW),
	design("Captain Biscuit", nil, "Saturday mornings", "tilt", "comic", YELLOW, INK, RED),
	design("Moon Over the Pier", nil, "Now showing", "frame", "round", INK, YELLOW, PINK),
	design("The Clockmaker's Cat", nil, "Starts Friday", "slab", "round", TEAL, WHITE, INK),
	design("Seven Buns at Sunrise", nil, "Late show at ten", "stripe", "comic", CORAL, WHITE, INK),
} :: { Design }

-- Streets ----------------------------------------------------------------------------------------------

-- Names for the roads Data/Town leaves unnamed, in the order it lists them: the avenues (east
-- and west by turns, from the old town outward), then the cross streets downtown and in the
-- civic quarter.
Signs.Streets = {
	"Ferry Avenue",
	"Orchard Avenue",
	"Lantern Avenue",
	"Museum Avenue",
	"East Shore Avenue",
	"West Shore Avenue",
	"Plum Street",
	"Loom Street",
	"School Lane",
	"Pell Street",
}

-- A street plate: white letters on blue.
Signs.Plate = { bg = rgb(30, 86, 180), fg = WHITE }

-- The cans in a vending machine's window.
Signs.Cans = { CORAL, YELLOW, TEAL, PINK, COBALT, VIOLET, GREEN, rgb(255, 140, 40), rgb(70, 180, 240), RED }

-- Picking ----------------------------------------------------------------------------------------------

-- a times b, kept to 32 bits, exact (a plain product would run past what a number holds)
local function mul32(a: number, b: number): number
	local ah, al = bit32.rshift(a, 16), bit32.band(a, 0xFFFF)
	local bh, bl = bit32.rshift(b, 16), bit32.band(b, 0xFFFF)
	local mid = bit32.band(ah * bl + al * bh, 0xFFFF)
	return (al * bl + mid * 65536) % 4294967296
end

-- A whole number from a spot (to the nearest stud) and a salt. The same in Roblox and in the
-- specs, since it is all whole number arithmetic.
function Signs.hash(x: number, y: number, z: number, salt: number?): number
	local h = bit32.bxor(
		mul32(math.floor(x + 0.5) % 4294967296, 73856093),
		mul32(math.floor(y + 0.5) % 4294967296, 19349663),
		mul32(math.floor(z + 0.5) % 4294967296, 83492791),
		mul32(math.floor(salt or 0) % 4294967296, 2654435761)
	)
	-- a last stir, so boards a stud apart land far from each other
	h = mul32(bit32.bxor(h, bit32.rshift(h, 15)), 2246822519)
	h = mul32(bit32.bxor(h, bit32.rshift(h, 13)), 3266489917)
	return bit32.bxor(h, bit32.rshift(h, 16))
end

-- With this salt no two shops of a kind on today's map share a name (it was found by trying
-- numbers). The Signs spec only insists that shops near each other differ: if shops are moved
-- and it complains, try other numbers here until it passes.
Signs.Salt = 842

-- The name over the door of the `kind` of shop whose building stands at x, z. Every board on one
-- building asks with the building's own spot, so they all agree.
function Signs.shopAt(kind: string, x: number, z: number): Design?
	local list = Signs.Shops[kind]
	if not list then
		return nil
	end
	return list[Signs.hash(x, 0, z, Signs.Salt) % #list + 1]
end

-- The advert on a board at this spot. `turn` tells the faces of one board apart, so its two
-- sides can sell different things.
function Signs.advertAt(x: number, y: number, z: number, turn: number?): Design
	return Signs.Adverts[Signs.hash(x, y, z, 100 + (turn or 0)) % #Signs.Adverts + 1]
end

function Signs.filmAt(x: number, y: number, z: number, turn: number?): Design
	return Signs.Films[Signs.hash(x, y, z, 200 + (turn or 0)) % #Signs.Films + 1]
end

-- Every road's name, in Data/Town's order.
function Signs.roadNames(): { string }
	local out = {}
	local spare = 0
	for i, road in Town.Roads do
		local name = road.name
		if type(name) ~= "string" then
			spare += 1
			name = Signs.Streets[(spare - 1) % #Signs.Streets + 1]
		end
		out[i] = name
	end
	return out
end

-- The name of the road nearest x, z. A plate runs along the road it names, so say which way the
-- plate runs (`alongX`) and a road running that way wins over a slightly nearer one across it.
function Signs.streetAt(x: number, z: number, alongX: boolean?): string
	local names = Signs.roadNames()
	local best, bestAt = 1, math.huge
	for i, road in Town.Roads do
		local x1, x2 = math.min(road[1], road[3]), math.max(road[1], road[3])
		local z1, z2 = math.min(road[2], road[4]), math.max(road[2], road[4])
		local dx = math.max(x1 - x, 0, x - x2)
		local dz = math.max(z1 - z, 0, z - z2)
		local d = math.sqrt(dx * dx + dz * dz)
		if alongX ~= nil and (road[2] == road[4]) ~= alongX then
			d += 60
		end
		if d < bestAt then
			best, bestAt = i, d
		end
	end
	return names[best]
end

-- The rows of cans in the vending machine at this spot: `rows` lists of `perRow` colours.
function Signs.cansAt(x: number, y: number, z: number, rows: number, perRow: number): { { Color3 } }
	local out = {}
	local h = Signs.hash(x, y, z, 300)
	for r = 1, rows do
		local row = {}
		for c = 1, perRow do
			-- a different run of colours on each shelf, and no two the same side by side
			row[c] = Signs.Cans[(h + r * 3 + c * (1 + (h + r) % 3)) % #Signs.Cans + 1]
			if c > 1 and row[c] == row[c - 1] then
				row[c] = Signs.Cans[(h + r * 3 + c * 4 + 1) % #Signs.Cans + 1]
			end
		end
		out[r] = row
	end
	return out
end

-- Words ------------------------------------------------------------------------------------------------

-- A word turned to read down a blade sign: one letter to a line.
function Signs.stack(word: string): string
	local letters = {}
	for ch in word:gmatch("%S") do
		table.insert(letters, ch)
	end
	return table.concat(letters, "\n")
end

-- The letter a shop's little hanging tile shows: the first of its name, past a leading "The".
function Signs.initial(name: string): string
	local rest = name:gsub("^The ", "")
	return rest:sub(1, 1):upper()
end

-- How far apart two colours are in lightness, the way the web's contrast rule counts it (1 for
-- the same, 21 for black on white). The spec holds every design to a floor, and the server uses
-- it to choose which colour a board's lamp throws.
function Signs.luminance(c: Color3): number
	local function lin(v: number): number
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end

function Signs.contrast(a: Color3, b: Color3): number
	local la, lb = Signs.luminance(a), Signs.luminance(b)
	return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05)
end

return Signs
