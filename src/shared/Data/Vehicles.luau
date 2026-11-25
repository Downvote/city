--!strict
-- The vehicles a player can buy and drive round the island. The user: "make vehicles, with faster
-- ones with bigger capacities costing more, and gem ones being the fastest". Bought with coins, each
-- one up the list is faster, takes more people and costs more; the two bought with gems are faster
-- than any of them. Each is drawn here in its own frame (the middle of its wheels at y 0, its front
-- toward -Z), as the Build mode pieces are, with where the driver and the passengers sit.
-- Services/Vehicles puts one together; client/World/Driving drives it (Sim/Vehicles holds the rules).

local Recipe = require(script.Parent.Parent.Build.Recipe)
local Colors = require(script.Parent.Parent.Util.Colors)

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

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
local TYRE = rgb(42, 42, 48)
local HUB = rgb(196, 196, 204)
local GLASS = rgb(170, 206, 226)
local LAMP = rgb(255, 240, 200)
local TAIL = rgb(214, 70, 70)
local TRIM = rgb(60, 60, 68)

-- A wheel at (x, z), its middle at y 0: a tyre and a hub, both turned to roll along Z.
local function wheel(r: R, x: number, z: number, radius: number, width: number)
	r:cyl(x, 0, z, width, radius * 2, "x", TYRE, "Rubber")
	r:cyl(x + (if x > 0 then 0.04 else -0.04), 0, z, width, radius, "x", HUB, "Metal")
end

-- A car: a body, a cabin with glass round it, four wheels, lamps front and back. `len` and `wid`
-- its length and width, `body` how tall the body is over the wheels' middle, `cab` the cabin's
-- height, `cabLen` its length and `cabAt` how far back its middle sits.
local function car(r: R, len: number, wid: number, body: number, cab: number, cabLen: number, cabAt: number, wr: number)
	local hl, hw = len / 2, wid / 2
	-- the body, from a little over the wheels' middle
	r:block(-hw, -wr * 0.35, -hl, hw, body, hl, r.c1, "SmoothPlastic")
	-- the cabin and its glass: the roof, then a pane on every side a hair proud of the frame
	local c1, c2 = cabAt - cabLen / 2, cabAt + cabLen / 2
	r:block(-hw + 0.25, body, c1, hw - 0.25, body + cab, c2, r.c1, "SmoothPlastic")
	r:block(-hw + 0.2, body + cab, c1 + 0.1, hw - 0.2, body + cab + 0.18, c2 - 0.1, r.c2, "SmoothPlastic")
	local g = body + 0.2
	r:add({
		shape = "Block",
		cf = CFrame.new(-hw + 0.22, g + (cab - 0.4) / 2, cabAt),
		size = Vector3.new(0.06, cab - 0.4, cabLen - 0.7),
		color = GLASS,
		mat = "Glass",
		transp = 0.25,
	})
	r:add({
		shape = "Block",
		cf = CFrame.new(hw - 0.22, g + (cab - 0.4) / 2, cabAt),
		size = Vector3.new(0.06, cab - 0.4, cabLen - 0.7),
		color = GLASS,
		mat = "Glass",
		transp = 0.25,
	})
	for _, z in { c1 - 0.03, c2 + 0.03 } do
		r:add({
			shape = "Block",
			cf = CFrame.new(0, g + (cab - 0.4) / 2, z),
			size = Vector3.new(wid - 1.1, cab - 0.4, 0.06),
			color = GLASS,
			mat = "Glass",
			transp = 0.25,
		})
	end
	-- bumpers, lamps
	r:block(-hw - 0.05, -wr * 0.4, -hl - 0.2, hw + 0.05, -wr * 0.05, -hl + 0.1, TRIM, "SmoothPlastic")
	r:block(-hw - 0.05, -wr * 0.4, hl - 0.1, hw + 0.05, -wr * 0.05, hl + 0.2, TRIM, "SmoothPlastic")
	for _, sx in { -1, 1 } do
		r:glow(
			r:block(
				sx * hw - sx * 0.7 - 0.35,
				body - 0.55,
				-hl - 0.06,
				sx * hw - sx * 0.7 + 0.35,
				body - 0.2,
				-hl + 0.02,
				LAMP,
				"Neon"
			),
			0
		)
		r:block(
			sx * hw - sx * 0.6 - 0.3,
			body - 0.55,
			hl - 0.02,
			sx * hw - sx * 0.6 + 0.3,
			body - 0.25,
			hl + 0.06,
			TAIL,
			"Neon"
		)
	end
	-- the wheels, just inside the corners
	local wz = hl - wr - 0.4
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			wheel(r, sx * (hw - 0.3), sz * wz, wr, 0.7)
		end
	end
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
		size = Vector3.new(1.6, 4.2, 5.6),
		hover = 0.8,
		driver = Vector3.new(0, 1.2, 0.5),
		passengers = {},
		color = "4FA9D9",
		draw = function(r: R)
			-- two small wheels, a low deck, a front shield and bars, a seat over the back wheel
			wheel(r, 0, -1.8, 0.8, 0.4)
			wheel(r, 0, 1.8, 0.8, 0.4)
			r:block(-0.45, -0.15, -1.4, 0.45, 0.25, 1.4, r.c1, "SmoothPlastic")
			r:block(-0.55, 0.25, 0.4, 0.55, 1.0, 2.2, r.c1, "SmoothPlastic")
			r:block(-0.5, 1.0, 0.5, 0.5, 1.25, 1.9, TRIM, "Leather")
			r:boxAt(
				CFrame.new(0, 1.2, -1.75) * CFrame.Angles(math.rad(-15), 0, 0),
				1.0,
				2.4,
				0.3,
				r.c1,
				"SmoothPlastic"
			)
			r:cyl(0, 2.45, -2.0, 0.14, 1.5, "x", TRIM, "Metal")
			r:glow(r:block(-0.25, 1.75, -2.05, 0.25, 2.05, -1.95, LAMP, "Neon"), 0)
		end,
	},
	{
		id = "hatch",
		name = "Little hatchback",
		blurb = "Room for a friend, and quicker than the scooter.",
		speed = 36,
		seats = 2,
		coins = 4000,
		size = Vector3.new(5, 4.6, 8),
		hover = 0.9,
		driver = Vector3.new(-0.9, 0.9, 0.3),
		passengers = { Vector3.new(0.9, 0.9, 0.3) },
		color = "E5843E",
		draw = function(r: R)
			car(r, 7.4, 4.6, 1.3, 1.9, 4.2, 0.8, 0.9)
		end,
	},
	{
		id = "family",
		name = "Family car",
		blurb = "Four seats and a good turn of speed.",
		speed = 44,
		seats = 4,
		coins = 9000,
		size = Vector3.new(5.4, 4.8, 10),
		hover = 1,
		driver = Vector3.new(-1, 1, -0.6),
		passengers = { Vector3.new(1, 1, -0.6), Vector3.new(-1, 1, 1.6), Vector3.new(1, 1, 1.6) },
		color = "4F78C8",
		draw = function(r: R)
			car(r, 9.4, 5, 1.4, 1.9, 5.4, 0.5, 1)
		end,
	},
	{
		id = "camper",
		name = "Camper van",
		blurb = "Six seats, a tall roof and a fair speed.",
		speed = 50,
		seats = 6,
		coins = 18000,
		size = Vector3.new(6, 6.6, 12),
		hover = 1.1,
		driver = Vector3.new(-1.1, 1.1, -3),
		passengers = {
			Vector3.new(1.1, 1.1, -3),
			Vector3.new(-1.1, 1.1, -0.4),
			Vector3.new(1.1, 1.1, -0.4),
			Vector3.new(-1.1, 1.1, 2.2),
			Vector3.new(1.1, 1.1, 2.2),
		},
		color = "F2DA6A",
		draw = function(r: R)
			car(r, 11.4, 5.6, 1.6, 3.4, 9.8, 0.4, 1.1)
			-- a white band round it and a rack on the roof
			r:block(-2.82, 1.6, -5.7, 2.82, 2.1, 5.7, r.c2, "SmoothPlastic")
			r:block(-2.2, 5.2, -3, 2.2, 5.4, 3.4, TRIM, "Metal")
		end,
	},
	{
		id = "bus",
		name = "Little bus",
		blurb = "Eight seats for the whole gang, and quick for its size.",
		speed = 54,
		seats = 8,
		coins = 30000,
		size = Vector3.new(6.2, 7, 16),
		hover = 1.2,
		driver = Vector3.new(-1.2, 1.2, -5.6),
		passengers = {
			Vector3.new(1.2, 1.2, -3.2),
			Vector3.new(-1.2, 1.2, -1.2),
			Vector3.new(1.2, 1.2, -1.2),
			Vector3.new(-1.2, 1.2, 1.2),
			Vector3.new(1.2, 1.2, 1.2),
			Vector3.new(-1.2, 1.2, 3.6),
			Vector3.new(1.2, 1.2, 3.6),
		},
		color = "6AAE86",
		draw = function(r: R)
			car(r, 15.4, 5.8, 1.7, 3.6, 14.6, 0.2, 1.2)
		end,
	},
	{
		id = "sports",
		name = "Sports car",
		blurb = "Low, loud and faster than anything coins can buy.",
		speed = 76,
		seats = 2,
		gems = 90,
		size = Vector3.new(5.2, 3.8, 9.4),
		hover = 0.9,
		driver = Vector3.new(-0.9, 0.6, 0.6),
		passengers = { Vector3.new(0.9, 0.6, 0.6) },
		color = "D95050",
		draw = function(r: R)
			car(r, 9, 4.8, 1.0, 1.4, 3.6, 0.9, 0.9)
			-- a spoiler on the back
			for _, sx in { -1, 1 } do
				r:block(sx * 1.8 - 0.1, 1.0, 3.9, sx * 1.8 + 0.1, 1.6, 4.2, TRIM, "Metal")
			end
			r:block(-2.3, 1.6, 3.7, 2.3, 1.75, 4.4, r.c1, "SmoothPlastic")
		end,
	},
	{
		id = "cruiser",
		name = "Glide cruiser",
		blurb = "The fastest thing on the island, with room for four.",
		speed = 88,
		seats = 4,
		gems = 160,
		size = Vector3.new(5.6, 4.2, 10.4),
		hover = 1,
		driver = Vector3.new(-1, 0.8, -0.4),
		passengers = { Vector3.new(1, 0.8, -0.4), Vector3.new(-1, 0.8, 1.6), Vector3.new(1, 0.8, 1.6) },
		color = "9460C0",
		draw = function(r: R)
			car(r, 10, 5.2, 1.2, 1.6, 5, 0.6, 1)
			-- glowing strips along its sides
			for _, sx in { -1, 1 } do
				r:block(sx * 2.62 - 0.04, 0.2, -4.4, sx * 2.62 + 0.04, 0.4, 4.4, rgb(150, 220, 255), "Neon")
			end
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
