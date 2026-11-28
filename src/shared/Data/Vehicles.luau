--!strict
-- The vehicles a player can buy and drive round the island. The user: "make vehicles, with faster
-- ones with bigger capacities costing more, and gem ones being the fastest". Bought with coins, each
-- one up the list is faster, takes more people and costs more; the ones bought with gems are faster
-- than any of them, and dearer and faster again up their own list. Then: "make cars and vechicles
-- more detailed, especially player bought ones. the scooter dosent look like a scooter" and "make
-- more vehicles ... for the endgame": every one is drawn from Data/VehicleKit (round wheels with
-- spokes, rounded bodies, arches, framed windows, seats and a steering wheel inside, lamps, grilles,
-- bumpers, mirrors and blank plates), the scooter is a step-through with its floorboard, apron and
-- column, and the list runs on past the little bus to a coach and an open-top bus, with a limo and
-- a hover car at the top of the gem ones.
--
-- Each is drawn here in its own frame (the middle of its wheels at y 0, its front toward -Z), as the
-- Build mode pieces are, with where the driver and the passengers sit: a seat is drawn under each.
-- Services/Vehicles puts one together; client/World/Driving drives it (Sim/Vehicles holds the rules).

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)
local VehicleKit = require(script.Parent.VehicleKit)

type R = Recipe.Recipe

export type Vehicle = {
	id: string,
	name: string,
	blurb: string,
	speed: number, -- studs a second, flat out
	seats: number, -- the driver and the passengers
	coins: number?, -- its price in coins, or
	gems: number?, -- in gems
	size: Vector3, -- its box
	hover: number, -- how high its frame rides over the road (the wheels' radius)
	driver: Vector3, -- where the driver sits, in its frame
	passengers: { Vector3 },
	color: string, -- its paint
	draw: (r: R) -> (),
}

local Kit = VehicleKit
local CHROME, TRIM, GLASS = Kit.CHROME, Kit.TRIM, Kit.GLASS
local round = Kit.round

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Where people sit: a row of seats across at height y and z.
local function row(xs: { number }, y: number, z: number): { Vector3 }
	local out = {}
	for _, x in xs do
		table.insert(out, Vector3.new(x, y, z))
	end
	return out
end

local function join(...: { Vector3 }): { Vector3 }
	local out = {}
	for _, list in { ... } do
		for _, v in list do
			table.insert(out, v)
		end
	end
	return out
end

-- Everyone's seat in a vehicle, the driver's first.
local function seatsOf(driver: Vector3, passengers: { Vector3 }): { Vector3 }
	return join({ driver }, passengers)
end

-- A spare wheel hung on the back at z (or the front: `dir` -1), its cover in the paint.
local function spare(r: R, y: number, z: number, R: number, color: Color3, dir: number?)
	local d = dir or 1
	round(r:cyl(0, y, z + d * 0.3, 0.5, R * 2, "z", Kit.TYRE, "Rubber"))
	round(r:cyl(0, y, z + d * 0.36, 0.5, R * 1.5, "z", color, Kit.Paint))
	round(r:cyl(0, y, z + d * 0.42, 0.5, R * 0.5, "z", CHROME, "Metal"))
end

-- Rails along a roof at height y from z1 to z2, on posts.
local function rails(r: R, x: number, y: number, z1: number, z2: number)
	for _, sx in { -1, 1 } do
		Kit.rod(
			r,
			Vector3.new(sx * x, y + 0.3, z1 + 0.2),
			Vector3.new(sx * x, y + 0.3, z2 - 0.2),
			0.14,
			CHROME,
			"Metal",
			true
		)
		for _, z in { z1 + 0.2, (z1 + z2) / 2, z2 - 0.2 } do
			r:block(sx * x - 0.07, y - 0.02, z - 0.08, sx * x + 0.07, y + 0.26, z + 0.08, TRIM, "Rubber")
		end
	end
end

-- Curtains drawn half across a side window from the inside, at x, over z1..z2.
local function curtains(r: R, x: number, y1: number, y2: number, z1: number, z2: number, color: Color3)
	for _, z in { z1, z2 } do
		local w = 0.55
		local zc = if z == z1 then z1 + w / 2 else z2 - w / 2
		r:block(x - 0.05, y1, zc - w / 2, x + 0.05, y2, zc + w / 2, color, "Fabric")
	end
	r:block(x - 0.05, y2, z1, x + 0.05, y2 + 0.14, z2, color, "Fabric")
end

local Vehicles = {}

Vehicles.list = {
	{
		id = "scooter",
		name = "Scooter",
		blurb = "Zips about town with one rider.",
		speed = 28,
		seats = 1,
		coins = 1200,
		size = Vector3.new(1.9, 3.5, 4.8),
		hover = 0.55,
		driver = Vector3.new(0, 1.25, 0.75),
		passengers = {},
		color = "7FC4C9",
		draw = function(r: R)
			-- a step-through scooter: small wheels, a floorboard to rest the feet on, the apron
			-- rising in front of the legs to the handlebars on their column, and the seat on the
			-- rounded body over the engine at the back
			local paint = r.c1
			Kit.wheel(r, 0, 0, -1.6, 0.55, 0.36, { spokes = 0, out = -1 })
			Kit.wheel(r, 0, 0, 1.5, 0.55, 0.36, { spokes = 0, out = -1 })
			-- the floorboard, with rubber strips along it and chrome runners on its edges
			r:block(-0.5, -0.05, -1.12, 0.5, 0.1, 0.45, paint, Kit.Paint)
			for k = -1, 1 do
				r:block(k * 0.26 - 0.07, 0.1, -0.95, k * 0.26 + 0.07, 0.14, 0.3, TRIM, "Rubber")
			end
			for _, sx in { -1, 1 } do
				r:block(sx * 0.5 - 0.04, 0.0, -1.1, sx * 0.5 + 0.04, 0.14, 0.42, CHROME, "Metal")
			end
			-- the apron, leaning back, with its trim down the middle
			Kit.at(r, CFrame.new(0, 0.05, -1.08) * CFrame.Angles(math.rad(14), 0, 0), function(q)
				Kit.roundBox(q, -0.56, 0, -0.08, 0.56, 1.8, 0.08, 0.22, paint)
				q:block(-0.05, 0.75, -0.13, 0.05, 1.5, -0.08, CHROME, "Metal")
				q:block(-0.22, 1.5, -0.13, 0.22, 1.58, -0.08, CHROME, "Metal")
			end)
			-- the mudguard curving over the front wheel
			local lr = 0.72
			for k = 0, 5 do
				local phi = math.rad(18) + math.rad(132) * (k + 0.5) / 6
				r:boxAt(
					CFrame.new(0, 0.05 + lr * math.sin(phi), -1.6 - lr * math.cos(phi))
						* CFrame.Angles(phi - math.pi / 2, 0, 0),
					0.5,
					0.12,
					2 * lr * math.sin(math.rad(11)) + 0.06,
					paint,
					Kit.Paint
				)
			end
			-- the steering column from the handlebars down to the mudguard, and the fork to the axle
			Kit.rod(r, Vector3.new(0, 1.95, -0.78), Vector3.new(0, 0.78, -1.3), 0.17, TRIM, "Metal")
			Kit.rod(r, Vector3.new(-0.06, 0.8, -1.3), Vector3.new(-0.27, 0, -1.6), 0.14, TRIM, "Metal", true)
			-- the headset with its round lamp, the speedometer on top, the bars and their grips
			Kit.roundBox(r, -0.36, 1.86, -1.0, 0.36, 2.2, -0.58, 0.14, paint)
			r:glow(Kit.lamp(r, 0, 2.02, -1.02, 0.36, -1, Kit.LAMP), 16, 1)
			round(r:cyl(0, 2.22, -0.72, 0.06, 0.3, "y", CHROME, "Metal"))
			round(r:cyl(0, 2.26, -0.72, 0.06, 0.22, "y", Kit.MIRROR, "Glass"))
			Kit.rod(r, Vector3.new(-0.62, 2.1, -0.76), Vector3.new(0.62, 2.1, -0.76), 0.12, CHROME, "Metal")
			for _, sx in { -1, 1 } do
				Kit.rod(
					r,
					Vector3.new(sx * 0.58, 2.1, -0.76),
					Vector3.new(sx * 0.86, 2.1, -0.76),
					0.16,
					TRIM,
					"Rubber",
					true
				)
				r:beam(
					Vector3.new(sx * 0.5, 2.14, -0.8),
					Vector3.new(sx * 0.82, 2.08, -0.96),
					0.06,
					0.06,
					CHROME,
					"Metal"
				)
				-- mirrors on stalks
				r:beam(
					Vector3.new(sx * 0.42, 2.14, -0.78),
					Vector3.new(sx * 0.62, 2.62, -0.86),
					0.06,
					0.06,
					CHROME,
					"Metal"
				)
				round(r:cyl(sx * 0.66, 2.72, -0.86, 0.08, 0.3, "z", CHROME, "Metal"))
				round(r:cyl(sx * 0.66, 2.72, -0.82, 0.06, 0.24, "z", Kit.MIRROR, "Glass"))
			end
			-- the rounded body over the engine, a chrome strip along each side
			Kit.roundBox(r, -0.48, 0.08, 0.3, 0.48, 0.98, 1.9, 0.42, paint)
			r:block(-0.4, 0.08, 0.42, 0.4, 0.22, 1.2, paint, Kit.Paint)
			for _, sx in { -1, 1 } do
				r:block(sx * 0.48 - sx * 0.01, 0.42, 0.62, sx * 0.48 + sx * 0.035, 0.48, 1.6, CHROME, "Metal")
			end
			-- the engine on the right, its exhaust out to the back
			r:block(0.18, -0.24, 0.55, 0.42, 0.12, 1.35, Kit.DISH, "Metal")
			round(r:cyl(0.36, -0.16, 1.55, 0.9, 0.3, "z", CHROME, "Metal"))
			round(r:cyl(0.36, -0.16, 2.02, 0.06, 0.18, "z", TRIM, "Metal"))
			-- the seat, a rail behind it, the tail lamp and a little plate
			Kit.roundBox(r, -0.38, 0.96, 0.05, 0.38, 1.45, 1.62, 0.2, Kit.SEAT, "Leather")
			r:block(-0.4, 0.92, 0.05, 0.4, 1.0, 1.62, CHROME, "Metal")
			for _, sx in { -1, 1 } do
				Kit.rod(r, Vector3.new(sx * 0.3, 1.1, 1.55), Vector3.new(sx * 0.3, 1.22, 1.98), 0.08, CHROME, "Metal")
			end
			Kit.rod(r, Vector3.new(-0.3, 1.22, 1.98), Vector3.new(0.3, 1.22, 1.98), 0.08, CHROME, "Metal", true)
			r:block(-0.22, 0.6, 1.86, 0.22, 0.82, 1.94, CHROME, "Metal")
			r:glow(r:block(-0.18, 0.63, 1.9, 0.18, 0.79, 1.97, Kit.TAIL, "Glass"), 0)
			r:block(-0.34, 0.24, 1.9, 0.34, 0.52, 1.94, TRIM, "Rubber")
			r:block(-0.3, 0.27, 1.94, 0.3, 0.49, 1.98, Kit.PLATE, "Metal")
		end,
	},
	{
		id = "hatch",
		name = "Little hatchback",
		blurb = "Room for a friend.",
		speed = 36,
		seats = 2,
		coins = 4000,
		size = Vector3.new(6.2, 5.7, 8.4),
		hover = 0.85,
		driver = Vector3.new(-0.95, 0.85, 0.5),
		passengers = { Vector3.new(0.95, 0.85, 0.5) },
		color = "E5843E",
		draw = function(r: R)
			Kit.car(r, {
				len = 7.6,
				wid = 4.8,
				R = 0.85,
				tw = 0.7,
				fa = -2.45,
				ra = 2.45,
				sill = -0.3,
				belt = 1.75,
				roof = 4.7,
				ws = { -1.5, -0.25 },
				bw = { 2.75, 3.55 },
				doors = { { -1.3, 1.55 } },
				roofPaint = r.c2,
				seats = seatsOf(Vector3.new(-0.95, 0.85, 0.5), { Vector3.new(0.95, 0.85, 0.5) }),
				inside = "full",
			})
		end,
	},
	{
		id = "pickup",
		name = "Pickup truck",
		blurb = "Three on the bench and a bed behind.",
		speed = 40,
		seats = 3,
		coins = 6500,
		size = Vector3.new(7, 6.3, 10.8),
		hover = 1.0,
		driver = Vector3.new(-1.55, 1.2, -0.3),
		passengers = { Vector3.new(0, 1.2, -0.3), Vector3.new(1.55, 1.2, -0.3) },
		color = "7FA7C2",
		draw = function(r: R)
			local m = Kit.car(r, {
				len = 10,
				wid = 5.6,
				R = 1.0,
				tw = 0.85,
				fa = -3.1,
				ra = 3.0,
				sill = -0.25,
				belt = 2.1,
				hood = 1.85,
				roof = 5.25,
				ws = { -2.0, -1.0 },
				bw = { 1.25, 1.4 },
				bed = 1.55,
				doors = { { -1.85, 1.2 } },
				arch = TRIM,
				bumper = CHROME,
				lamps = "wide",
				spokes = 4,
				seats = seatsOf(
					Vector3.new(-1.55, 1.2, -0.3),
					{ Vector3.new(0, 1.2, -0.3), Vector3.new(1.55, 1.2, -0.3) }
				),
				inside = "full",
			})
			-- a rack over the bed's front, behind the cab's back window
			for _, sx in { -1, 1 } do
				r:block(sx * (m.hw - 0.12) - 0.08, 2.1, 1.75, sx * (m.hw - 0.12) + 0.08, 3.5, 1.9, CHROME, "Metal")
			end
			Kit.rod(
				r,
				Vector3.new(-m.hw + 0.12, 3.5, 1.82),
				Vector3.new(m.hw - 0.12, 3.5, 1.82),
				0.16,
				CHROME,
				"Metal",
				true
			)
			-- a crate and a sack in the bed
			r:block(0.6, 0.97, 2.6, 2.0, 1.9, 3.8, rgb(176, 132, 88), "WoodPlanks")
			r:lump(
				CFrame.new(-1.2, 1.35, 3.4) * CFrame.Angles(0, 0.4, 0.2),
				1.2,
				0.8,
				1.0,
				rgb(214, 196, 160),
				"Fabric"
			)
		end,
	},
	{
		id = "family",
		name = "Family car",
		blurb = "Four seats and a boot.",
		speed = 44,
		seats = 4,
		coins = 9000,
		size = Vector3.new(6.4, 5.9, 11.2),
		hover = 0.95,
		driver = Vector3.new(-1.05, 1, -0.9),
		passengers = { Vector3.new(1.05, 1, -0.9), Vector3.new(-1.05, 1, 1.45), Vector3.new(1.05, 1, 1.45) },
		color = "4F78C8",
		draw = function(r: R)
			Kit.car(r, {
				len = 10.4,
				wid = 5,
				R = 0.95,
				tw = 0.75,
				fa = -3.35,
				ra = 3.35,
				sill = -0.3,
				belt = 1.7,
				hood = 1.3,
				roof = 4.85,
				ws = { -2.3, -0.95 },
				bw = { 2.6, 3.75 },
				doors = { { -2.1, 0.25 }, { 0.4, 2.75 } },
				posts = { 0.32 },
				chrome = true,
				seats = seatsOf(
					Vector3.new(-1.05, 1, -0.9),
					{ Vector3.new(1.05, 1, -0.9), Vector3.new(-1.05, 1, 1.45), Vector3.new(1.05, 1, 1.45) }
				),
				inside = "full",
			})
		end,
	},
	{
		id = "offroad",
		name = "Off-roader",
		blurb = "Five seats, big wheels, a spare on the back.",
		speed = 47,
		seats = 5,
		coins = 13500,
		size = Vector3.new(7.2, 7.2, 12.4),
		hover = 1.15,
		driver = Vector3.new(-1.2, 1.3, -1.1),
		passengers = {
			Vector3.new(1.2, 1.3, -1.1),
			Vector3.new(-1.55, 1.3, 1.6),
			Vector3.new(0, 1.3, 1.6),
			Vector3.new(1.55, 1.3, 1.6),
		},
		color = "7E9A72",
		draw = function(r: R)
			local m = Kit.car(r, {
				len = 11,
				wid = 5.6,
				R = 1.15,
				tw = 0.95,
				fa = -3.55,
				ra = 3.55,
				sill = -0.15,
				belt = 2.25,
				roof = 5.3,
				ws = { -2.65, -1.75 },
				bw = { 5.05, 5.3 },
				doors = { { -2.45, 0.2 }, { 0.35, 2.9 } },
				posts = { 0.28, 3.4 },
				arch = TRIM,
				bumper = TRIM,
				rad = 0.3,
				spokes = 4,
				rim = rgb(160, 162, 170),
				seats = seatsOf(Vector3.new(-1.2, 1.3, -1.1), {
					Vector3.new(1.2, 1.3, -1.1),
					Vector3.new(-1.55, 1.3, 1.6),
					Vector3.new(0, 1.3, 1.6),
					Vector3.new(1.55, 1.3, 1.6),
				}),
				inside = "full",
			})
			rails(r, m.cx - 0.3, 5.3, -1.6, 5.1)
			spare(r, 1.4, m.tail, 1.0, r.c1)
			-- a guard under the nose
			r:block(-1.4, -0.45, m.nose - 0.35, 1.4, -0.05, m.nose + 0.4, Kit.DISH, "Metal")
		end,
	},
	{
		id = "camper",
		name = "Camper van",
		blurb = "Six seats under a tall roof.",
		speed = 50,
		seats = 6,
		coins = 18000,
		size = Vector3.new(7.2, 8.0, 13.8),
		hover = 1.0,
		driver = Vector3.new(-1.2, 1.1, -3.3),
		passengers = {
			Vector3.new(1.2, 1.1, -3.3),
			Vector3.new(-1.2, 1.1, -0.5),
			Vector3.new(1.2, 1.1, -0.5),
			Vector3.new(-1.2, 1.1, 2.3),
			Vector3.new(1.2, 1.1, 2.3),
		},
		color = "E3B04B",
		draw = function(r: R)
			local m = Kit.car(r, {
				len = 12.4,
				wid = 5.8,
				R = 1.0,
				tw = 0.8,
				fa = -4.3,
				ra = 4.0,
				sill = -0.2,
				belt = 2.1,
				roof = 5.6,
				ws = { -5.4, -4.95 },
				bw = { 5.95, 6.05 },
				inset = 0.22,
				rad = 0.5,
				doors = { { -5.0, -3.2 }, { -1.9, 1.0 } },
				posts = { -2.9, 1.2, 3.9 },
				roofPaint = r.c2,
				bumper = CHROME,
				spokes = 0,
				rim = r.c2,
				seats = seatsOf(Vector3.new(-1.2, 1.1, -3.3), {
					Vector3.new(1.2, 1.1, -3.3),
					Vector3.new(-1.2, 1.1, -0.5),
					Vector3.new(1.2, 1.1, -0.5),
					Vector3.new(-1.2, 1.1, 2.3),
					Vector3.new(1.2, 1.1, 2.3),
				}),
				inside = "full",
			})
			-- a white band round it under the windows
			for _, sx in { -1, 1 } do
				r:block(
					sx * m.hw - sx * 0.02,
					1.35,
					m.nose + 0.5,
					sx * m.hw + sx * 0.07,
					1.75,
					m.tail - 0.5,
					r.c2,
					Kit.Paint
				)
			end
			-- curtains in the back windows, a rack on the roof with a box and a ladder up the back
			for _, sx in { -1, 1 } do
				curtains(r, sx * (m.cx - 0.32), 2.3, 4.9, 1.4, 3.7, rgb(214, 120, 96))
			end
			rails(r, m.cx - 0.4, 5.6, -3.6, 5.2)
			Kit.roundBox(r, -1.4, 5.92, -2.6, 1.4, 6.9, 2.4, 0.3, r.c2)
			for _, sx in { -1, 1 } do
				r:block(sx * 1.1 - 0.06, 0.6, m.tail + 0.04, sx * 1.1 + 0.06, 5.9, m.tail + 0.16, CHROME, "Metal")
			end
			for y = 1.2, 5.4, 0.7 do
				r:block(-1.1, y - 0.05, m.tail + 0.06, 1.1, y + 0.05, m.tail + 0.14, CHROME, "Metal")
			end
			spare(r, 1.25, m.nose, 0.8, r.c2, -1)
		end,
	},
	{
		id = "bus",
		name = "Little bus",
		blurb = "Eight seats for the whole gang.",
		speed = 54,
		seats = 8,
		coins = 30000,
		size = Vector3.new(7.4, 7.6, 16.4),
		hover = 1.15,
		driver = Vector3.new(-1.3, 1.25, -5.4),
		passengers = {
			Vector3.new(1.3, 1.25, -5.4),
			Vector3.new(-1.3, 1.25, -1.0),
			Vector3.new(1.3, 1.25, -1.0),
			Vector3.new(-1.3, 1.25, 1.4),
			Vector3.new(1.3, 1.25, 1.4),
			Vector3.new(-1.3, 1.25, 3.8),
			Vector3.new(1.3, 1.25, 3.8),
		},
		color = "6AAE86",
		draw = function(r: R)
			local passengers = {
				Vector3.new(1.3, 1.25, -5.4),
				Vector3.new(-1.3, 1.25, -1.0),
				Vector3.new(1.3, 1.25, -1.0),
				Vector3.new(-1.3, 1.25, 1.4),
				Vector3.new(1.3, 1.25, 1.4),
				Vector3.new(-1.3, 1.25, 3.8),
				Vector3.new(1.3, 1.25, 3.8),
			}
			local m = Kit.car(r, {
				len = 15.6,
				wid = 6,
				R = 1.15,
				tw = 0.85,
				fa = -6.0,
				ra = 5.0,
				sill = -0.15,
				belt = 2.35,
				roof = 5.75,
				ws = { -7.25, -7.0 },
				bw = { 7.55, 7.65 },
				inset = 0.2,
				rad = 0.45,
				posts = { -4.6, -2.9, 0.2, 2.6, 5.0 },
				roofPaint = r.c2,
				bumper = TRIM,
				lamps = "wide",
				spokes = 0,
				seats = seatsOf(Vector3.new(-1.3, 1.25, -5.4), passengers),
				inside = "full",
			})
			-- the folding door on the kerb side, its two glass leaves in a dark frame
			r:block(m.hw - 0.02, -0.05, -4.55, m.hw + 0.1, 5.0, -2.95, TRIM, "Rubber")
			for _, z in { -4.15, -3.35 } do
				r:block(m.hw + 0.1, 0.15, z - 0.36, m.hw + 0.14, 4.8, z + 0.36, GLASS, "Glass").transp = 0.3
			end
			-- the sign over the windscreen, lit at night, and vents on the roof
			r:block(-1.8, 4.65, m.nose + 0.25, 1.8, 5.25, m.nose + 0.42, TRIM, "Rubber")
			r:glow(r:block(-1.65, 4.72, m.nose + 0.2, 1.65, 5.18, m.nose + 0.26, rgb(255, 214, 120), "Glass"), 0)
			for _, z in { -3.5, 2.5 } do
				Kit.roundBox(r, -0.9, 5.7, z - 0.9, 0.9, 6.0, z + 0.9, 0.12, rgb(210, 206, 196))
			end
		end,
	},
	{
		id = "coach",
		name = "Tour coach",
		blurb = "Eleven seats up high, and big windows.",
		speed = 58,
		seats = 11,
		coins = 50000,
		size = Vector3.new(7.8, 8.4, 20),
		hover = 1.2,
		driver = Vector3.new(-1.4, 1.7, -7.3),
		passengers = join(
			row({ -1.4, 1.4 }, 1.7, -4.9),
			row({ -1.4, 1.4 }, 1.7, -2.5),
			row({ -1.4, 1.4 }, 1.7, -0.1),
			row({ -1.4, 1.4 }, 1.7, 2.3),
			row({ -1.4, 1.4 }, 1.7, 4.7)
		),
		color = "5C7FB8",
		draw = function(r: R)
			local passengers = join(
				row({ -1.4, 1.4 }, 1.7, -4.9),
				row({ -1.4, 1.4 }, 1.7, -2.5),
				row({ -1.4, 1.4 }, 1.7, -0.1),
				row({ -1.4, 1.4 }, 1.7, 2.3),
				row({ -1.4, 1.4 }, 1.7, 4.7)
			)
			local m = Kit.car(r, {
				len = 19,
				wid = 6.4,
				R = 1.2,
				tw = 0.9,
				fa = -5.8,
				ra = 5.6,
				sill = -0.1,
				belt = 2.7,
				roof = 6.6,
				ws = { -9.2, -8.7 },
				bw = { 9.2, 9.35 },
				inset = 0.2,
				rad = 0.5,
				posts = { -6.1, -3.7, -1.3, 1.1, 3.5, 5.9 },
				roofPaint = r.c2,
				bumper = TRIM,
				lamps = "wide",
				seats = seatsOf(Vector3.new(-1.4, 1.7, -7.3), passengers),
				inside = "full",
			})
			-- the lockers for the bags, low along each side, and a white stripe over them
			for _, sx in { -1, 1 } do
				for _, z in { -3.2, -0.6, 2.0 } do
					for _, e in { z - 1.2, z + 1.2 } do
						Kit.seam(r, sx * m.hw, sx, e, 0.1, 1.5)
					end
					r:block(sx * m.hw - sx * 0.01, 0.1, z - 1.2, sx * m.hw + sx * 0.035, 0.15, z + 1.2, TRIM, "Rubber")
					Kit.handle(r, sx * m.hw, sx, 1.2, z)
				end
				r:block(
					sx * m.hw - sx * 0.02,
					1.75,
					m.nose + 0.6,
					sx * m.hw + sx * 0.035,
					2.05,
					m.tail - 0.4,
					r.c2,
					Kit.Paint
				)
			end
			-- the door, the sign, the mirrors out on their long arms
			r:block(m.hw - 0.02, 0.1, -8.75, m.hw + 0.1, 5.8, -7.45, TRIM, "Rubber")
			r:block(m.hw + 0.1, 0.3, -8.6, m.hw + 0.14, 5.6, -7.6, GLASS, "Glass").transp = 0.3
			r:block(-2.2, 5.6, m.nose + 0.25, 2.2, 6.25, m.nose + 0.42, TRIM, "Rubber")
			r:glow(r:block(-2.05, 5.67, m.nose + 0.2, 2.05, 6.18, m.nose + 0.26, rgb(255, 214, 120), "Glass"), 0)
			for _, sx in { -1, 1 } do
				r:beam(
					Vector3.new(sx * (m.hw - 0.1), 5.6, m.nose + 0.4),
					Vector3.new(sx * (m.hw + 0.5), 5.4, m.nose - 0.2),
					0.1,
					0.1,
					TRIM,
					"Rubber"
				)
				Kit.roundBox(
					r,
					sx * (m.hw + 0.5) - 0.2,
					4.4,
					m.nose - 0.4,
					sx * (m.hw + 0.5) + 0.2,
					5.4,
					m.nose,
					0.1,
					r.c1
				)
			end
			Kit.roundBox(r, -1.2, 6.55, 0, 1.2, 6.95, 3.6, 0.15, rgb(210, 206, 196))
		end,
	},
	{
		id = "opentop",
		name = "Open-top bus",
		blurb = "Seventeen seats, and the top deck has no roof.",
		speed = 62,
		seats = 17,
		coins = 80000,
		size = Vector3.new(7.8, 10.2, 20),
		hover = 1.25,
		driver = Vector3.new(-1.4, 1.4, -7.5),
		passengers = join(
			row({ -1.4, 1.4 }, 1.4, -4.4),
			row({ -1.4, 1.4 }, 1.4, -1.6),
			row({ -1.4, 1.4 }, 1.4, 1.2),
			row({ -1.4, 1.4 }, 5.9, -6.6),
			row({ -1.4, 1.4 }, 5.9, -3.8),
			row({ -1.4, 1.4 }, 5.9, -1.0),
			row({ -1.4, 1.4 }, 5.9, 1.8),
			row({ -1.4, 1.4 }, 5.9, 4.6)
		),
		color = "C2594F",
		draw = function(r: R)
			local below =
				join(row({ -1.4, 1.4 }, 1.4, -4.4), row({ -1.4, 1.4 }, 1.4, -1.6), row({ -1.4, 1.4 }, 1.4, 1.2))
			local m = Kit.car(r, {
				len = 19,
				wid = 6.4,
				R = 1.25,
				tw = 0.95,
				fa = -5.8,
				ra = 5.6,
				sill = -0.1,
				belt = 2.5,
				roof = 5.55,
				ws = { -9.2, -8.9 },
				bw = { 9.25, 9.35 },
				inset = 0.12,
				rad = 0.5,
				posts = { -6.0, -3.0, 0, 3.0, 6.0 },
				roofPaint = r.c1,
				bumper = TRIM,
				spokes = 0,
				seats = seatsOf(Vector3.new(-1.4, 1.4, -7.5), below),
				inside = "full",
			})
			-- a cream band between the decks
			for _, sx in { -1, 1 } do
				r:block(
					sx * m.hw - sx * 0.02,
					4.55,
					m.nose + 0.4,
					sx * m.hw + sx * 0.04,
					5.0,
					m.tail - 0.4,
					r.c2,
					Kit.Paint
				)
			end
			-- the top deck: waist high sides with a rail along them, a low screen at the front and
			-- the seats in pairs
			local top = 5.55
			for _, sx in { -1, 1 } do
				Kit.roundBox(
					r,
					sx * m.hw - (if sx > 0 then 0.28 else 0),
					top - 0.1,
					m.nose + 0.2,
					sx * m.hw + (if sx < 0 then 0.28 else 0),
					top + 1.6,
					m.tail - 0.2,
					0.12,
					r.c1
				)
				Kit.rod(
					r,
					Vector3.new(sx * (m.hw - 0.14), top + 2.25, m.nose + 0.5),
					Vector3.new(sx * (m.hw - 0.14), top + 2.25, m.tail - 0.5),
					0.12,
					CHROME,
					"Metal",
					true
				)
				for z = m.nose + 0.5, m.tail - 0.4, 2.3 do
					r:block(
						sx * (m.hw - 0.14) - 0.05,
						top + 1.6,
						z - 0.05,
						sx * (m.hw - 0.14) + 0.05,
						top + 2.25,
						z + 0.05,
						CHROME,
						"Metal"
					)
				end
			end
			Kit.roundBox(r, -m.hw + 0.1, top - 0.1, m.nose + 0.2, m.hw - 0.1, top + 1.6, m.nose + 0.5, 0.12, r.c1)
			Kit.roundBox(r, -m.hw + 0.1, top - 0.1, m.tail - 0.5, m.hw - 0.1, top + 1.6, m.tail - 0.2, 0.12, r.c1)
			r:block(-m.hw + 0.4, top + 1.6, m.nose + 0.28, m.hw - 0.4, top + 2.6, m.nose + 0.36, GLASS, "Glass").transp =
				0.35
			r:block(-m.hw + 0.3, top + 2.6, m.nose + 0.24, m.hw - 0.3, top + 2.7, m.nose + 0.4, CHROME, "Metal")
			for _, at in
				join(
					row({ -1.4, 1.4 }, 5.9, -6.6),
					row({ -1.4, 1.4 }, 5.9, -3.8),
					row({ -1.4, 1.4 }, 5.9, -1.0),
					row({ -1.4, 1.4 }, 5.9, 1.8),
					row({ -1.4, 1.4 }, 5.9, 4.6)
				)
			do
				Kit.seat(r, at, 1.3, rgb(170, 60, 64), "Leather", true)
			end
			-- the sign over the windscreen and the door
			r:block(-2.0, 4.0, m.nose + 0.2, 2.0, 4.5, m.nose + 0.4, TRIM, "Rubber")
			r:glow(r:block(-1.85, 4.06, m.nose + 0.15, 1.85, 4.44, m.nose + 0.21, rgb(255, 214, 120), "Glass"), 0)
			r:block(m.hw - 0.02, 0.1, -8.75, m.hw + 0.1, 4.4, -7.45, TRIM, "Rubber")
			r:block(m.hw + 0.1, 0.3, -8.6, m.hw + 0.14, 4.2, -7.6, GLASS, "Glass").transp = 0.3
		end,
	},
	{
		id = "sports",
		name = "Sports car",
		blurb = "Low, loud and open to the sky.",
		speed = 76,
		seats = 2,
		gems = 90,
		size = Vector3.new(6.0, 4.0, 10.4),
		hover = 0.9,
		driver = Vector3.new(-1.0, 0.45, 0.7),
		passengers = { Vector3.new(1.0, 0.45, 0.7) },
		color = "D95050",
		draw = function(r: R)
			local m = Kit.car(r, {
				len = 9.6,
				wid = 5.0,
				R = 0.9,
				tw = 0.85,
				fa = -3.1,
				ra = 3.05,
				sill = -0.4,
				belt = 1.35,
				hood = 0.95,
				ws = { -0.9, -0.3 },
				doors = { { -0.7, 1.9 } },
				spokes = 5,
				rim = rgb(60, 60, 68),
				hub = CHROME,
				seatColor = rgb(60, 44, 46),
				seats = seatsOf(Vector3.new(-1.0, 0.45, 0.7), { Vector3.new(1.0, 0.45, 0.7) }),
				inside = "full",
			})
			-- the windscreen in its frame, two hoops behind the seats
			r:block(-2.1, 1.3, -0.95, 2.1, 1.42, -0.75, TRIM, "Rubber")
			Kit.at(r, CFrame.new(0, 1.35, -0.85) * CFrame.Angles(math.rad(32), 0, 0), function(q)
				q:block(-2.0, 0, -0.03, 2.0, 1.2, 0.03, GLASS, "Glass").transp = 0.3
				for _, sx in { -1, 1 } do
					q:block(sx * 2.05 - 0.06, 0, -0.06, sx * 2.05 + 0.06, 1.3, 0.06, CHROME, "Metal")
				end
				q:block(-2.11, 1.24, -0.06, 2.11, 1.32, 0.06, CHROME, "Metal")
			end)
			for _, sx in { -1, 1 } do
				Kit.rod(
					r,
					Vector3.new(sx * 1.0 - 0.5, 1.35, 1.85),
					Vector3.new(sx * 1.0 - 0.5, 2.35, 1.85),
					0.16,
					CHROME,
					"Metal"
				)
				Kit.rod(
					r,
					Vector3.new(sx * 1.0 + 0.5, 1.35, 1.85),
					Vector3.new(sx * 1.0 + 0.5, 2.35, 1.85),
					0.16,
					CHROME,
					"Metal"
				)
				Kit.rod(
					r,
					Vector3.new(sx * 1.0 - 0.5, 2.35, 1.85),
					Vector3.new(sx * 1.0 + 0.5, 2.35, 1.85),
					0.16,
					CHROME,
					"Metal",
					true
				)
				-- vents behind the front wheels
				for k = 0, 2 do
					r:block(
						sx * m.hw - sx * 0.01,
						0.35 + k * 0.18,
						-1.9,
						sx * m.hw + sx * 0.035,
						0.43 + k * 0.18,
						-1.3,
						TRIM,
						"Rubber"
					)
				end
			end
			-- the stripes over it, the spoiler on the boot, two pipes out of the back
			for _, sx in { -1, 1 } do
				r:block(sx * 0.4 - 0.2, 1.35, 2.2, sx * 0.4 + 0.2, 1.39, m.tail - 0.3, r.c2, Kit.Paint)
				r:block(sx * 0.4 - 0.2, 0.96, m.nose + 0.4, sx * 0.4 + 0.2, 1.0, -1.6, r.c2, Kit.Paint)
				r:block(sx * 1.9 - 0.08, 1.35, 4.0, sx * 1.9 + 0.08, 1.85, 4.3, TRIM, "Metal")
				round(r:cyl(sx * 0.7, -0.25, m.tail, 0.5, 0.26, "z", CHROME, "Metal"))
			end
			Kit.roundBox(r, -2.4, 1.85, 3.75, 2.4, 2.02, 4.6, 0.07, r.c1)
		end,
	},
	{
		id = "cruiser",
		name = "Glide cruiser",
		blurb = "Four seats under a glass roof, and glowing trim.",
		speed = 88,
		seats = 4,
		gems = 160,
		size = Vector3.new(7.0, 5.9, 11.4),
		hover = 1,
		driver = Vector3.new(-1.05, 0.95, -0.8),
		passengers = { Vector3.new(1.05, 0.95, -0.8), Vector3.new(-1.05, 0.95, 1.55), Vector3.new(1.05, 0.95, 1.55) },
		color = "9460C0",
		draw = function(r: R)
			local glow = rgb(150, 220, 255)
			local m = Kit.car(r, {
				len = 10.6,
				wid = 5.4,
				R = 1.0,
				tw = 0.85,
				fa = -3.4,
				ra = 3.4,
				sill = -0.35,
				belt = 1.55,
				hood = 1.2,
				roof = 4.75,
				ws = { -2.4, -1.2 },
				bw = { 2.6, 4.2 },
				rad = 0.55,
				doors = { { -2.2, 0.3 }, { 0.45, 2.9 } },
				roofPaint = rgb(90, 110, 140),
				spokes = 0,
				rim = rgb(70, 70, 82),
				hub = glow,
				lamps = "wide",
				grille = false,
				seatColor = rgb(230, 228, 236),
				seats = seatsOf(Vector3.new(-1.05, 0.95, -0.8), {
					Vector3.new(1.05, 0.95, -0.8),
					Vector3.new(-1.05, 0.95, 1.55),
					Vector3.new(1.05, 0.95, 1.55),
				}),
				inside = "full",
			})
			-- a glass roof over the cabin, glowing strips along the sides and under the nose
			r:block(-m.cx + 0.2, 4.76, -0.8, m.cx - 0.2, 4.8, 2.3, GLASS, "Glass").transp = 0.3
			for _, sx in { -1, 1 } do
				r:glow(r:block(sx * m.hw - sx * 0.01, 0.05, -2.0, sx * m.hw + sx * 0.05, 0.17, 2.0, glow, "Neon"), 0)
				r:glow(
					r:block(
						sx * (m.hw - 0.4) - 0.05,
						1.21,
						m.nose + 0.6,
						sx * (m.hw - 0.4) + 0.05,
						1.25,
						-2.6,
						glow,
						"Neon"
					),
					0
				)
			end
			r:glow(r:block(-1.6, -0.1, m.nose - 0.06, 1.6, 0.02, m.nose + 0.1, glow, "Neon"), 0)
			-- a fin on each side of the tail
			for _, sx in { -1, 1 } do
				r:wedge(CFrame.new(sx * (m.hw - 0.3), 1.85, 4.6), 0.18, 0.6, 1.4, r.c1, Kit.Paint)
			end
		end,
	},
	{
		id = "limo",
		name = "Stretch limo",
		blurb = "Six seats in leather, and chrome everywhere.",
		speed = 96,
		seats = 6,
		gems = 250,
		size = Vector3.new(7.0, 6.0, 17.2),
		hover = 1,
		driver = Vector3.new(-1.1, 1.0, -4.3),
		passengers = {
			Vector3.new(1.1, 1.0, -4.3),
			Vector3.new(-1.1, 1.0, -0.6),
			Vector3.new(1.1, 1.0, -0.6),
			Vector3.new(-1.1, 1.0, 2.6),
			Vector3.new(1.1, 1.0, 2.6),
		},
		color = "34323C",
		draw = function(r: R)
			local m = Kit.car(r, {
				len = 16.4,
				wid = 5.4,
				R = 1.0,
				tw = 0.85,
				fa = -5.9,
				ra = 5.3,
				sill = -0.3,
				belt = 1.75,
				hood = 1.4,
				roof = 4.95,
				ws = { -5.6, -4.3 },
				bw = { 4.9, 6.1 },
				doors = { { -5.3, -3.2 }, { -1.9, 0.6 }, { 1.4, 3.9 } },
				posts = { -3.0, 0.9, 4.15 },
				chrome = true,
				bumper = CHROME,
				spokes = 6,
				seatColor = rgb(214, 196, 170),
				seats = seatsOf(Vector3.new(-1.1, 1.0, -4.3), {
					Vector3.new(1.1, 1.0, -4.3),
					Vector3.new(-1.1, 1.0, -0.6),
					Vector3.new(1.1, 1.0, -0.6),
					Vector3.new(-1.1, 1.0, 2.6),
					Vector3.new(1.1, 1.0, 2.6),
				}),
				inside = "full",
				glass = rgb(70, 80, 96),
				glassTransp = 0.2,
			})
			-- chrome down the sides and a little flag on each wing
			for _, sx in { -1, 1 } do
				r:block(
					sx * m.hw - sx * 0.01,
					0.55,
					m.nose + 1.2,
					sx * m.hw + sx * 0.04,
					0.63,
					m.tail - 1.0,
					CHROME,
					"Metal"
				)
				r:block(
					sx * (m.hw - 0.5) - 0.03,
					1.4,
					m.nose + 1.0,
					sx * (m.hw - 0.5) + 0.03,
					2.1,
					m.nose + 1.06,
					CHROME,
					"Metal"
				)
				r:block(
					sx * (m.hw - 0.5) - 0.02,
					1.85,
					m.nose + 1.06,
					sx * (m.hw - 0.5) + 0.02,
					2.1,
					m.nose + 1.5,
					rgb(214, 176, 96),
					"Fabric"
				)
			end
		end,
	},
	{
		id = "hover",
		name = "Hover car",
		blurb = "No wheels at all. The fastest thing on the island.",
		speed = 106,
		seats = 4,
		gems = 400,
		size = Vector3.new(6.6, 6.0, 11.0),
		hover = 1.3,
		driver = Vector3.new(-1.05, 0.7, -0.8),
		passengers = { Vector3.new(1.05, 0.7, -0.8), Vector3.new(-1.05, 0.7, 1.5), Vector3.new(1.05, 0.7, 1.5) },
		color = "56B8C4",
		draw = function(r: R)
			local glow = rgb(170, 240, 255)
			local m = Kit.car(r, {
				len = 10.2,
				wid = 5.2,
				R = 1.0,
				tw = 0.8,
				fa = -3.3,
				ra = 3.3,
				sill = -0.4,
				belt = 1.4,
				hood = 1.15,
				roof = 4.55,
				ws = { -2.5, -1.2 },
				bw = { 2.4, 3.9 },
				rad = 0.5,
				doors = { { -2.3, 0.3 }, { 0.45, 2.9 } },
				roofPaint = r.c2,
				lamps = "wide",
				grille = false,
				wheels = false,
				seatColor = rgb(236, 234, 240),
				seats = seatsOf(Vector3.new(-1.05, 0.7, -0.8), {
					Vector3.new(1.05, 0.7, -0.8),
					Vector3.new(-1.05, 0.7, 1.5),
					Vector3.new(1.05, 0.7, 1.5),
				}),
				inside = "full",
			})
			-- a white band round its waist and fins at the back
			for _, sx in { -1, 1 } do
				r:block(sx * m.hw - sx * 0.02, 0.45, -4.0, sx * m.hw + sx * 0.04, 0.6, 4.0, r.c2, Kit.Paint)
				r:wedge(CFrame.new(sx * (m.hw - 0.3), 1.75, 4.2), 0.16, 0.7, 1.4, r.c1, Kit.Paint)
			end
			-- four lift pads where wheels would be, each a glowing ring round a dark disc
			for _, z in { -3.3, 3.3 } do
				for _, sx in { -1, 1 } do
					round(r:cyl(sx * 1.6, -0.52, z, 0.3, 1.9, "y", Kit.DISH, "Metal"))
					r:glow(round(r:cyl(sx * 1.6, -0.66, z, 0.12, 1.6, "y", glow, "Neon")), 0)
					round(r:cyl(sx * 1.6, -0.7, z, 0.12, 1.0, "y", Kit.WELL, "Metal"))
				end
			end
			r:glow(r:block(-2.0, -0.46, -2.6, 2.0, -0.4, 2.6, glow, "Neon"), 10, 1, glow)
		end,
	},
} :: { Vehicle }

local byId: { [string]: Vehicle } = {}
for _, v in Vehicles.list do
	byId[v.id] = v
end

function Vehicles.get(id: any): Vehicle?
	return if type(id) == "string" then byId[id] else nil
end

-- Its parts, in its own frame, in its paint (and white for the second colour).
function Vehicles.prims(v: Vehicle): { Recipe.Prim }
	local r = Recipe.new(Colors.fromHex(v.color), Color3.fromRGB(250, 248, 240))
	v.draw(r)
	return r.prims
end

return Vehicles
